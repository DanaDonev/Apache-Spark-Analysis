SELECT
  publication_year,
  FIRST(title) AS best_work,
  MAX(cited_by_count) AS citations
FROM uni_works
WHERE publication_year IS NOT NULL
GROUP BY publication_year
ORDER BY publication_year;
