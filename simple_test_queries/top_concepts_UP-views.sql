--different simple queries created as views
--one row per author per institution from UP
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

--SELECT * FROM exploded_institutions LIMIT 10;

--one row per work per concept with score >= 0.5
CREATE OR REPLACE TEMP VIEW filtered_concepts AS
SELECT
  w.id AS work_id,
  concept.id AS concept_id,
  concept.display_name AS concept_name,
  concept.score AS score,
  concept.level AS level
FROM works w
LATERAL VIEW EXPLODE(w.concepts) concept AS concept
WHERE concept.score >= 0.5;

--one row per work with a column for its broadest (biggest level)
CREATE OR REPLACE TEMP VIEW broadest_concepts_per_work AS
SELECT *
FROM (
  SELECT
    fc.work_id,
    fc.concept_id,
    fc.concept_name,
    fc.score,
    fc.level,
    ROW_NUMBER() OVER (PARTITION BY fc.work_id ORDER BY fc.level ASC) AS rn
  FROM filtered_concepts fc
  JOIN exploded_institutions ei
    ON fc.work_id = ei.work_id
) t
WHERE rn = 1;

--total number of works from exploaded_institution (from UP)
CREATE OR REPLACE TEMP VIEW up_work_count AS
SELECT COUNT(DISTINCT work_id) AS total_works
FROM exploded_institutions;

--10 most common concepts (from UP)
SELECT
  bcpw.concept_id,
  bcpw.concept_name,
  bcpw.level AS concept_level,
  COUNT(*) AS work_count,
  ROUND(100.0 * COUNT(*) / tw.total_works, 2) AS percentage_of_works
FROM broadest_concepts_per_work bcpw
CROSS JOIN up_work_count tw
GROUP BY bcpw.concept_id, bcpw.concept_name, bcpw.level, tw.total_works
ORDER BY work_count DESC
LIMIT 10;

