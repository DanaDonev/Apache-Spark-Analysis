SELECT
  a.display_name AS author,
  COUNT(DISTINCT u.id) AS works_count
FROM uni_works u
JOIN exploded_authorships a ON u.id = a.work_id
GROUP BY a.display_name
ORDER BY works_count DESC
LIMIT 20;
