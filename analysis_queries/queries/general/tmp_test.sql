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
        --w.field,
        get_json_object(w.primary_topic, '$.display_name') AS topic,
	auth_struct.author.id AS author_id,
        auth_struct.author.display_name AS author_name,
        get_json_object(auth_struct.institutions[0], '$.id') AS institution_id,
        get_json_object(auth_struct.institutions[0], '$.display_name') AS institution_name,
        get_json_object(auth_struct.institutions[0], '$.country_code') AS country_code
	--get_json_object(inst, '$.id') AS institution_id,
        --get_json_object(inst, '$.display_name') AS institution_name,
        --get_json_object(inst, '$.country_code') AS country_code
        --cb.year AS cited_year,
        --cb.cited_by_count AS citations_in_year
    FROM filtered w
    LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
    --LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst
    WHERE size(auth_struct.institutions) > 0
--LATERAL VIEW OUTER EXPLODE(w.counts_by_year) cb AS cb
),

--SELECT * FROM exploded_institutions LIMIT 10;


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
    WHERE country_code = 'SI'
),

--SELECT * FROM exploded_institutions LIMIT 50;
topic_count AS (
    SELECT
        institution_id,
        topic,
        COUNT(DISTINCT work_id) AS topic_count
    FROM slovenian_exploded
    WHERE topic IS NOT NULL
    GROUP BY institution_id, topic
    --ORDER BY topic_count DESC
),

--main is with rank = 1
main_topic_per_institution AS (
    SELECT
        institution_id,
        topic,
        topic_count,
        ROW_NUMBER() OVER (PARTITION BY institution_id ORDER BY topic_count DESC) AS rank
    FROM topic_count
),

--SELECT * FROM main_topic_per_institution LIMIT 30;

slovenian_authors AS (
    SELECT *
    FROM exploded_institutions
    WHERE country_code = 'SI'
),

--number ot institutions and countries connected to each slovenian work
work_collaborations AS (
    SELECT
        work_id,
        COUNT(DISTINCT institution_id) AS num_institutions,
        COUNT(DISTINCT country_code) AS num_countries
    FROM slovenian_authors
    GROUP BY work_id
),

--number of works that have collaboration and international one
institution_collaborations AS (
    SELECT
        s.institution_id,
        s.institution_name,
        COUNT(DISTINCT CASE WHEN wc.num_institutions > 1 THEN s.work_id END) AS total_collaborations,
        COUNT(DISTINCT CASE WHEN wc.num_countries > 1 THEN s.work_id END) AS collaborations_with_other_country,
        COUNT(DISTINCT s.work_id) AS total_works
    FROM slovenian_authors s
    JOIN work_collaborations wc
      ON s.work_id = wc.work_id
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
    FROM slovenian_authors
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
)

SELECT * FROM institution_collaborations LIMIT 10;
/*
SELECT
    publication_year,
    institution_name,
    COUNT(DISTINCT work_id) AS number_of_works,
    SUM(cited_by_count) AS number_of_citations,
    max_by(title, cited_by_count) AS best_work,
    MAX(cited_by_count) AS citations,
    max_by(author_name, cited_by_count) AS author_most_cited_work
FROM exploded_institutions
WHERE publication_year >= 2000
  AND institution_name IN ('University of Primorska', 'University of Ljubljana', 'University of Maribor')
GROUP BY publication_year, institution_name
ORDER BY publication_year, institution_name;

--SELECT *
--FROM institution_collaborations
--ORDER BY total_collaborations DESC
--LIMIT 50;
--SELECT institution_id, topic AS main_topic, topic_count
--FROM main_topic_per_institution
--WHERE rank = 1
--ORDER BY topic_count DESC
--LIMIT 10;

