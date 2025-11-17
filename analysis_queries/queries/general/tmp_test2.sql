INSERT OVERWRITE DIRECTORY 'analysis_queries/results/general/main_query2'
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
        --w.field,
        get_json_object(w.primary_topic, '$.display_name') AS topic,
        auth_struct.author.id AS author_id,
        auth_struct.author.display_name AS author_name,
        get_json_object(auth_struct.institutions[0], '$.id') AS institution_id,
	CASE
            WHEN get_json_object(auth_struct.institutions[0], '$.display_name') IN
                ('Jožef Stefan Institute', 'Jožef Stefan International Postgraduate School')
                THEN 'Jožef Stefan'
            ELSE get_json_object(auth_struct.institutions[0], '$.display_name')
        END AS institution_name,
        --get_json_object(auth_struct.institutions[0], '$.display_name') AS institution_name,
        get_json_object(auth_struct.institutions[0], '$.country_code') AS country_code
        --cb.year AS cited_year,
        --cb.cited_by_count AS citations_in_year
    FROM filtered w
    LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
    --LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst
    WHERE size(auth_struct.institutions) > 0
),

work_collaborations AS (
    SELECT
        work_id,
        COUNT(DISTINCT institution_id) AS institution_count,
        COUNT(DISTINCT country_code) AS country_count
    FROM exploded_institutions
    GROUP BY work_id
),

--author_stats AS (
--    SELECT
--        publication_year,
--        institution_name,
 --       author_name,
 --       COUNT(DISTINCT work_id) AS works_per_author,
 --       ROW_NUMBER() OVER (PARTITION BY publication_year, institution_name ORDER BY COUNT(DISTINCT work_id) DESC) AS rn
 --   FROM exploded_institutions
 --   GROUP BY publication_year, institution_name, author_name
--)
author_works AS (
    SELECT
        publication_year,
        institution_name,
        author_name,
        COUNT(DISTINCT work_id) AS works_per_author
    FROM exploded_institutions
    GROUP BY publication_year, institution_name, author_name
),
author_stats AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY publication_year, institution_name ORDER BY works_per_author DESC) AS rn
    FROM author_works
)


SELECT 'publication_year','institution_name','number_of_works','number_of_citations','number_of_collaborative_works','number_of_international_works','best_work','best_work_citations','most_cited_work_author','most_productive_author','number_of_works_mpa'
UNION ALL

SELECT
    cast(e.publication_year as string),
    e.institution_name,
    cast(COUNT(DISTINCT e.work_id) as string) AS number_of_works,
    cast(SUM(cited_by_count) as string) AS number_of_citations,
    cast(SUM(CASE WHEN wc.institution_count > 1 THEN 1 ELSE 0 END) as string)
        AS number_of_collaborative_works,
    cast(SUM(CASE WHEN wc.country_count > 1 THEN 1 ELSE 0 END) as string)
        AS number_of_international_works,
    max_by(title, cited_by_count) AS best_work,
    cast(MAX(cited_by_count) as string) AS best_work_citations,
    max_by(e.author_name, cited_by_count) AS most_cited_work_author,
    msa.author_name AS most_productive_author,
    cast(msa.works_per_author as string) AS number_of_works_mpa
FROM exploded_institutions e
JOIN work_collaborations wc
    ON e.work_id = wc.work_id
LEFT JOIN author_stats msa ON e.publication_year = msa.publication_year
			AND e.institution_name = msa.institution_name
			AND msa.rn = 1
WHERE e.publication_year >= 2000
  AND e.institution_name IN ('University of Primorska', 'University of Ljubljana', 'University of Maribor', 'Jožef Stefan')
GROUP BY e.publication_year, e.institution_name, msa.author_name, msa.works_per_author
ORDER BY publication_year, institution_name;
