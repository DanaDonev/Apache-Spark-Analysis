SELECT
  a.display_name AS author,
  SUM(u.cited_by_count) AS total_citations
FROM uni_works u
JOIN exploded_authorships a ON u.id = a.work_id
GROUP BY a.display_name
ORDER BY total_citations DESC
LIMIT 20;
