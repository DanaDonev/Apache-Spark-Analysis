SELECT
  u.publication_year,
  COUNT(DISTINCT u.id) AS total_works,
  SUM(CASE WHEN COUNT(DISTINCT i.country_code) > 1 THEN 1 ELSE 0 END) AS intl_collab_works
FROM uni_works u
JOIN exploded_institutions i ON u.id = i.work_id
WHERE u.publication_year IS NOT NULL
GROUP BY u.publication_year
ORDER BY u.publication_year;
