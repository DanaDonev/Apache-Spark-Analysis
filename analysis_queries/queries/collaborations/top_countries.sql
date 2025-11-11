SELECT
  i.country_code,
  COUNT(DISTINCT u.id) AS num_collaborations
FROM uni_works u
JOIN exploded_institutions i ON u.id = i.work_id
WHERE i.institution_id != 'https://openalex.org/I118905719'
GROUP BY i.country_code
ORDER BY num_collaborations DESC
LIMIT 20;
