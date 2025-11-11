INSERT OVERWRITE DIRECTORY 'openalex_analysis_2/results/general/works_citations_per_year'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT
  publication_year,
  COUNT(*) AS num_works,
  SUM(cited_by_count) AS total_citations
FROM uni_works
WHERE publication_year IS NOT NULL
GROUP BY publication_year
ORDER BY publication_year;
