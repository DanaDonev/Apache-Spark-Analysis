INSERT OVERWRITE DIRECTORY 'analysis_queries/results/general/main_query1'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','

WITH filtered AS (
    SELECT *
    FROM works w
    WHERE get_json_object(w.primary_topic, '$.field.display_name') = 'Computer Science'
),

exploded_institutions AS (
    SELECT
        w.id AS work_id,
        w.title,
        w.publication_year,
        w.cited_by_count,
        get_json_object(w.primary_topic, '$.display_name') AS topic,

        auth_struct.author.id AS author_id,
        auth_struct.author.display_name AS author_name,

        get_json_object(auth_struct.institutions[0], '$.id') AS institution_id,
        CASE
            WHEN get_json_object(auth_struct.institutions[0], '$.display_name')
                 IN ('Jožef Stefan Institute', 'Jožef Stefan International Postgraduate School')
            THEN 'Jožef Stefan'
            ELSE get_json_object(auth_struct.institutions[0], '$.display_name')
        END AS institution_name,
        get_json_object(auth_struct.institutions[0], '$.country_code') AS country_code
    FROM filtered w
    LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
    WHERE size(auth_struct.institutions) > 0
),

slovenian_exploded AS (
    SELECT DISTINCT
        work_id,
        publication_year,
        cited_by_count,
        topic,
        institution_id,
        institution_name,
        country_code
    FROM exploded_institutions
    WHERE institution_name IN (
        'University of Primorska',
        'University of Ljubljana',
        'University of Maribor',
        'Jožef Stefan'
    )
),

topic_count AS (
    SELECT
        institution_id,
        institution_name,
        topic,
        COUNT(DISTINCT work_id) AS topic_count
    FROM slovenian_exploded
    WHERE topic IS NOT NULL
    GROUP BY institution_id, institution_name, topic
),

main_topic_per_institution AS (
    SELECT
        institution_name,
        max_by(topic, topic_count) AS top_topic,
        MAX(topic_count) AS top_topic_count
    FROM topic_count
    GROUP BY institution_name
),

work_collaborations AS (
    SELECT
        work_id,
        COUNT(DISTINCT institution_id) AS num_institutions,
        COUNT(DISTINCT country_code) AS num_countries
    FROM slovenian_exploded
    GROUP BY work_id
),

institution_collaborations AS (
    SELECT
        s.institution_id,
        s.institution_name,
        COUNT(DISTINCT CASE WHEN wc.num_institutions > 1 THEN s.work_id END) AS total_collaborations,
        COUNT(DISTINCT CASE WHEN wc.num_countries > 1 THEN s.work_id END) AS international_collaborations,
        COUNT(DISTINCT s.work_id) AS total_works
    FROM slovenian_exploded s
    JOIN work_collaborations wc ON s.work_id = wc.work_id
    GROUP BY s.institution_id, s.institution_name
),

author_stats AS (
    SELECT
        institution_id,
        institution_name,
        author_id,
        author_name,
        COUNT(DISTINCT work_id) AS work_count,
        SUM(cited_by_count) AS total_citations
    FROM exploded_institutions
    GROUP BY institution_id, institution_name, author_id, author_name
),

best_authors_by_work AS (
    SELECT
        institution_id,
        institution_name,
        author_id,
        author_name,
        work_count,
        total_citations
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY institution_id
                   ORDER BY work_count DESC, total_citations DESC
               ) AS rn
        FROM author_stats
    ) ranked
    WHERE rn = 1
),

best_authors_by_citations AS (
    SELECT
        institution_id,
        institution_name,
        author_id,
        author_name,
        work_count,
        total_citations
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY institution_id
                   ORDER BY total_citations DESC, work_count DESC
               ) AS rn
        FROM author_stats
    ) ranked
    WHERE rn = 1
),

institution_stats AS (
    SELECT
        institution_name,
        COUNT(DISTINCT work_id) AS number_of_works,
        SUM(cited_by_count) AS number_of_citations,
        MAX(cited_by_count) AS best_work_citations
    FROM slovenian_exploded
    GROUP BY institution_name
)

SELECT
    'institution_name',
    'number_of_works',
    'number_of_citations',
    'main_topic',
    'number_of_works_with_collaborations',
    'number_of_works_with_international_collaborations',
    'most_productive_author',
    'most_cited_author'
UNION ALL
SELECT
    s.institution_name,
    CAST(s.number_of_works AS STRING),
    CAST(s.number_of_citations AS STRING),
    mt.top_topic,
    CAST(ic.total_collaborations AS STRING),
    CAST(ic.international_collaborations AS STRING),
    pa.author_name,
    ca.author_name
FROM institution_stats s
LEFT JOIN main_topic_per_institution mt
    ON s.institution_name = mt.institution_name
LEFT JOIN institution_collaborations ic
    ON s.institution_name = ic.institution_name
LEFT JOIN best_authors_by_work pa
    ON s.institution_name = pa.institution_name
LEFT JOIN best_authors_by_citations ca
    ON s.institution_name = ca.institution_name;
