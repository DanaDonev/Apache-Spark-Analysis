WITH exploded_institutions AS (
    SELECT
        w.id AS work_id,
        w.publication_year,
        w.cited_by_count AS for_comparison_of_total,
        get_json_object(w.primary_topic, '$.field.display_name') AS field,
        get_json_object(inst, '$.id') AS institution_id,
        get_json_object(inst, '$.display_name') AS institution_name,
        get_json_object(inst, '$.country_code') AS country_code,
        cb.year AS cited_year,
        cb.cited_by_count AS citations_in_year
    FROM works w
    LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
    LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst
    LATERAL VIEW OUTER EXPLODE(w.counts_by_year) cb AS cb
),

yearly AS (
    SELECT
        publication_year,
        institution_name,
        COUNT(DISTINCT work_id) AS number_of_works,
        SUM(CASE WHEN cited_year = publication_year THEN citations_in_year ELSE 0 END) AS citations_same_year,
	SUM(DISTINCT for_comparison_of_total) AS for_comparison_of_total
    FROM exploded_institutions
    WHERE publication_year IS NOT NULL
      AND country_code = 'SI'
      AND field = 'Computer Science'
    GROUP BY publication_year, institution_name
),

totals AS (
    SELECT
        NULL AS publication_year,  -- For alignment in UNION
        institution_name,
        COUNT(DISTINCT work_id) AS total_number_of_works,
        SUM(CASE WHEN cited_year = publication_year THEN citations_in_year ELSE 0 END) AS total_citations_same_year,
	SUM(DISTINCT for_comparison_of_total) AS for_comparison_of_total
    FROM exploded_institutions
    WHERE publication_year IS NOT NULL
      AND country_code = 'SI'
      AND field = 'Computer Science'
    GROUP BY institution_name
)

SELECT
    publication_year,
    institution_name,
    number_of_works,
    citations_same_year,
    for_comparison_of_total
FROM yearly

UNION ALL

SELECT
    publication_year,  -- NULL for total row
    institution_name,
    total_number_of_works AS number_of_works,
    total_citations_same_year AS citations_same_year,
    for_comparison_of_total
FROM totals

ORDER BY institution_name, publication_year;
