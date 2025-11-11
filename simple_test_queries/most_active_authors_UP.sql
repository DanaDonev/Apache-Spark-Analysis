--works from the UP one row per author per institution
CREATE OR REPLACE TEMP VIEW exploded_authors AS
SELECT
  w.id AS work_id,
  w.publication_year,
  auth.author.id AS author_id,
  auth.author.display_name AS author_name,
  get_json_object(inst, '$.id') AS institution_id,
  get_json_object(inst, '$.display_name') AS institution_name
FROM works w
LATERAL VIEW EXPLODE(w.authorships) auth AS auth
LATERAL VIEW EXPLODE(auth.institutions) inst AS inst
WHERE get_json_object(inst, '$.id') = 'https://openalex.org/I118905719'
  AND w.publication_year IS NOT NULL;

--first 20 authors with most works from the exploded_authors
SELECT
  author_id,
  author_name,
  COUNT(DISTINCT work_id) AS num_works,
  MIN(publication_year) AS first_pub_year,
  MAX(publication_year) AS last_pub_year,
  (MAX(publication_year) - MIN(publication_year) + 1) AS publishing_span_years
FROM exploded_authors
GROUP BY author_id, author_name
ORDER BY num_works DESC
LIMIT 20;

