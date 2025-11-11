INSERT OVERWRITE DIRECTORY 'openalex_analysis_2/results/general/avg_citations_per_work'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT
  AVG(cited_by_count) AS avg_citations
FROM uni_works;
