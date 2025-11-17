INSERT OVERWRITE DIRECTORY 'analysis_queries/results/general/main_query2'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','

WITH filtered AS (
    SELECT *
    FROM works
    WHERE get_json_object(primary_topic, '$.field.display_name') = 'Computer Science'
),

--one row per work per author
exploded_institutions AS (
    SELECT
        w.id AS work_id,
        w.title,
        w.publication_year,
        w.cited_by_count,
        auth.author.display_name AS author_name,
        get_json_object(auth.institutions[0], '$.country_code') AS country_code,
        CASE
            WHEN get_json_object(auth.institutions[0], '$.display_name')
                 IN ('Jožef Stefan Institute', 'Jožef Stefan International Postgraduate School')
            THEN 'Jožef Stefan'
            ELSE get_json_object(auth.institutions[0], '$.display_name')
        END AS institution_name
    FROM filtered w
    LATERAL VIEW EXPLODE(w.authorships) auth AS auth
    WHERE size(auth.institutions) > 0
),

-- number of distinct institutions & countries per work
work_collaborations AS (
    SELECT
        work_id,
        COUNT(DISTINCT institution_name) AS institution_count,
        COUNT(DISTINCT country_code) AS country_count
    FROM exploded_institutions
    GROUP BY work_id
),

-- number of collaboration works per year per isntitution
collab_stats AS (
    SELECT
        e.publication_year,
        e.institution_name,
        SUM(CASE WHEN wc.institution_count > 1 THEN 1 ELSE 0 END) AS number_of_collaborative_works,
        SUM(CASE WHEN wc.country_count > 1 THEN 1 ELSE 0 END) AS number_of_international_works
    FROM exploded_institutions e
    JOIN work_collaborations wc ON e.work_id = wc.work_id
    GROUP BY e.publication_year, e.institution_name
),

-- the basic counts per year per institution 
institution_year_stats AS (
    SELECT
        publication_year,
        institution_name,
        COUNT(DISTINCT work_id) AS number_of_works,
        SUM(cited_by_count) AS number_of_citations,
        MAX(cited_by_count) AS best_work_citations,
        max_by(title, cited_by_count) AS best_work,
        max_by(author_name, cited_by_count) AS most_cited_work_author
    FROM exploded_institutions
    GROUP BY publication_year, institution_name
),

-- number of works per author per year per institution
author_works AS (
    SELECT
        publication_year,
        institution_name,
        author_name,
        COUNT(DISTINCT work_id) AS works_per_author
    FROM exploded_institutions
    GROUP BY publication_year, institution_name, author_name
),

-- ordering the authors from most productive to least
author_stats AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY publication_year, institution_name
            ORDER BY works_per_author DESC
        ) AS rn
    FROM author_works
)

/*SELECT 'publication_year',
	'institution_name',
	'number_of_works',
	'number_of_citations',
	'number_of_collaborative_works',
	'number_of_international_works',
	'best_work',
	'best_work_citations',
	'most_cited_work_author',
	'most_productive_author',
	'number_of_works_mpa'

UNION ALL
*/
SELECT
    CAST(s.publication_year as string),
    cast(s.institution_name as string),
    CAST(s.number_of_works as string),
    CAST(s.number_of_citations AS string),
    CAST(c.number_of_collaborative_works AS STRING),
    CAST(c.number_of_international_works AS STRING),
    cast(s.best_work as string),
    CAST(s.best_work_citations AS STRING),
    cast(s.most_cited_work_author as string),
    cast(a.author_name as string) AS most_productive_author,
    CAST(a.works_per_author AS STRING) AS number_of_works_mpa
FROM institution_year_stats s
LEFT JOIN collab_stats c
       ON s.publication_year = c.publication_year
      AND s.institution_name = c.institution_name
LEFT JOIN author_stats a
       ON s.publication_year = a.publication_year
      AND s.institution_name = a.institution_name
      AND a.rn = 1
WHERE	s.institution_name IN (
        'University of Primorska',
        'University of Ljubljana',
        'University of Maribor',
        'Jožef Stefan'
  )
ORDER BY s.publication_year, s.institution_name;
