SELECT
  a.display_name AS author,
  AVG(u.cited_by_count) AS avg_citations
FROM uni_works u
JOIN exploded_authorships a ON u.id = a.work_id
GROUP BY a.display_name
HAVING COUNT(DISTINCT u.id) >= 5
ORDER BY avg_citations DESC
LIMIT 20;
