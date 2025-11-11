INSERT OVERWRITE DIRECTORY 'openalex_analysis_2/results/general/top_concepts'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT
  c.concept_name AS concept,
  COUNT(DISTINCT u.id) AS num_works
FROM uni_works u
JOIN exploded_concepts c ON u.id = c.work_id
GROUP BY c.concept_name
ORDER BY num_works DESC
LIMIT 20;
