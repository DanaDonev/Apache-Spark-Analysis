SELECT
  id,
  title,
  SIZE(authorships) AS num_authors
FROM uni_works
ORDER BY num_authors DESC
LIMIT 10;
