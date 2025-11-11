WITH filtered AS (
    SELECT *
    FROM works w
    WHERE country_code = 'SI'
      AND field = 'Computer Science'
),

exploded_institutions AS (
    SELECT
        w.id AS work_id,
        w.publication_year,
        w.cited_by_count AS for_comparison_of_total,
        get_json_object(w.primary_topic, '$.field.display_name') AS field,
        get_json_object(w.primary_topic, '$.display_name') AS topic,
        get_json_object(inst, '$.id') AS institution_id,
        get_json_object(inst, '$.display_name') AS institution_name,
        get_json_object(inst, '$.country_code') AS country_code,
        cb.year AS cited_year,
        cb.cited_by_count AS citations_in_year
    FROM filtered w
    LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
    LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst
    LATERAL VIEW OUTER EXPLODE(w.counts_by_year) cb AS cb
),

-- filtered AS (
--     SELECT *
--     FROM exploded_institutions
--     WHERE country_code = 'SI'
--       AND field = 'Computer Science'
-- ),

-- main_topic AS (
--     SELECT
--         institution_id,
--         topic,
--         COUNT(topic) AS topic_count --COUNT OF WORKS PER TOPIC
--     FROM filtered
--     GROUP BY institution_id, topic
--     HAVING topic IS NOT NULL
--     ORDER BY topic_count DESC
--     LIMIT 1 OVER (PARTITION BY institution_id)  --MAIN TOPIC PER INSTITUTION
-- ),
main_topic AS (
    -- compute counts per (institution, topic), then pick the top topic per institution
    SELECT institution_id, topic, topic_count
    FROM (
        SELECT
            s.institution_id,
            s.topic,
            s.topic_count,
            ROW_NUMBER() OVER (PARTITION BY s.institution_id ORDER BY s.topic_count DESC) AS rn
        FROM (
            SELECT institution_id, topic, COUNT(*) AS topic_count
            FROM exploded_institutions filtered
            WHERE topic IS NOT NULL
            GROUP BY institution_id, topic
        ) s
    ) t
    WHERE rn = 1
),

collaborations AS (
    SELECT
        institution_id,
        institution_name,
        country_code,
        COUNT(DISTINCT work_id) AS collaboration_works,  --WORKS WITH COLLABORATIONS
        COUNT(DISTINCT IF(f2.country_code != filtered.country_code, work_id, NULL)) AS international_collaboration_works, --WORKS WITH INTERNATIONAL COLLABORATIONS
        COUNT(*) AS collaborations,   --COLLABORATION INSTANCES
        COUNT(IF(f2.country_code != filtered.country_code, 1, NULL)) AS international_collaborations --INTERNATIONAL COLLABORATIONS
    FROM exploded_institutions filtered
    JOIN filtered AS f2 ON filtered.work_id = f2.work_id AND filtered.institution_id != f2.institution_id
    GROUP BY institution_id, institution_name, country_code
),

totals AS (
    SELECT
        institution_id,
        institution_name, --INSTITUTION
        COUNT(DISTINCT work_id) AS total_number_of_works, --TOTAL NUMBER OF WORKS
	    SUM(DISTINCT for_comparison_of_total) AS for_comparison_of_total,  --TOTAL NUMBER OF CITATIONS
        topic AS main_topic,  --MAIN TOPIC,
        topic_count AS topic_count  --COUNT OF WORKS IN MAIN TOPIC
    FROM exploded_institutions filtered
    JOIN main_topic mt ON filtered.institution_id = mt.institution_id
    WHERE filtered.topic = mt.topic
    GROUP BY institution_id, institution_name
)

SELECT
    *,
    c.collaboration_works,
    c.international_collaboration_works,
    c.collaborations,
    c.international_collaborations
FROM totals t
LEFT JOIN collaborations c ON t.institution_id = c.institution_id
ORDER BY total_number_of_works DESC;
