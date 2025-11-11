--works from the university of primorska one row per author per institution
CREATE OR REPLACE TEMP VIEW exploded_institutions AS
SELECT
  w.id AS work_id,
  w.publication_year,
  get_json_object(inst, '$.id') AS institution_id,
  get_json_object(inst, '$.display_name') AS display_name,
  get_json_object(inst, '$.country_code') AS country_code
FROM works w
LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst
WHERE get_json_object(inst, '$.id') = "https://openalex.org/I118905719";

SELECT * FROM exploded_institutions LIMIT 10;

--works per year from the exploded view from most recent year
SELECT
  w.publication_year,
  COUNT(DISTINCT w.id) AS num_works
FROM works w
JOIN exploded_institutions ei ON w.id = ei.work_id
WHERE w.publication_year IS NOT NULL
GROUP BY w.publication_year
ORDER BY w.publication_year;

--iternational collaboration per year SO BAD!!
--SELECT
--  w.publication_year,
--  COUNT(DISTINCT ei.country_code) AS num_countries
--FROM works w
--JOIN exploded_institutions ei ON w.id = ei.work_id
--WHERE w.publication_year IS NOT NULL
--  AND EXISTS (
--    SELECT 1
--    FROM exploded_institutions ei2
--    WHERE ei2.work_id = w.id
--      AND ei2.institution_id = 'https://openalex.org/I118905719'
--  )
--GROUP BY w.publication_year
--ORDER BY w.publication_year;

--works from all institutions (per author per instutition), not just UP
CREATE OR REPLACE TEMP VIEW exploded_institutions_all AS
SELECT
  w.id AS work_id,
  w.publication_year,
  get_json_object(inst, '$.id') AS institution_id,
  get_json_object(inst, '$.display_name') AS display_name,
  get_json_object(inst, '$.country_code') AS country_code
FROM works w
LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst;


--top 10 longest collaboration partners
SELECT
  ei.display_name AS partner_institution,
  ei.country_code,
  MIN(w.publication_year) AS first_collab_year,
  MAX(w.publication_year) AS last_collab_year,
  (MAX(w.publication_year) - MIN(w.publication_year) + 1) AS collaboration_span_years,
  COUNT(DISTINCT w.id) AS num_collaborative_works
FROM works w
JOIN exploded_institutions_all ei ON w.id = ei.work_id
WHERE ei.institution_id != 'https://openalex.org/I118905719'
  AND w.publication_year IS NOT NULL
  AND EXISTS (
    SELECT 1
    FROM exploded_institutions_all ei2
    WHERE ei2.work_id = w.id
      AND ei2.institution_id = 'https://openalex.org/I118905719'
  )
GROUP BY ei.display_name, ei.country_code
ORDER BY collaboration_span_years DESC, num_collaborative_works DESC
LIMIT 10;


--top 20 collaboration countries with UP
SELECT
  ei.country_code AS partner_country,
  COUNT(DISTINCT ei.work_id) AS num_collaborations
FROM exploded_institutions_all ei
WHERE ei.country_code IS NOT NULL
  AND ei.institution_id != 'https://openalex.org/I118905719'
  AND ei.work_id IN (
    SELECT work_id
    FROM exploded_institutions_all
    WHERE institution_id = 'https://openalex.org/I118905719'
  )
GROUP BY ei.country_code
ORDER BY num_collaborations DESC
LIMIT 20;

--top collaboration institutions for UP
SELECT
  ei.display_name AS partner_institution,
  ei.country_code,
  COUNT(DISTINCT ei.work_id) AS num_collaborations
FROM exploded_institutions_all ei
WHERE ei.institution_id != 'https://openalex.org/I118905719'
  AND ei.work_id IN (
    SELECT work_id
    FROM exploded_institutions_all
    WHERE institution_id = 'https://openalex.org/I118905719'
  )
GROUP BY ei.display_name, ei.country_code
ORDER BY num_collaborations DESC;
