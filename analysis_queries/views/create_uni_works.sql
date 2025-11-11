CREATE OR REPLACE VIEW exploded_institutions AS
SELECT
  w.id AS work_id,
  w.publication_year,
  get_json_object(inst, '$.id') AS institution_id,
  get_json_object(inst, '$.display_name') AS display_name,
  get_json_object(inst, '$.country_code') AS country_code
FROM works w
LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst;
--WHERE get_json_object(inst, '$.id') = "https://openalex.org/I118905719";

CREATE OR REPLACE VIEW uni_works AS
SELECT
  w.*,
  ei.institution_id,
  ei.display_name AS institution_name,
  ei.country_code AS institution_country
FROM works w
JOIN exploded_institutions ei ON w.id = ei.work_id
WHERE ei.institution_id = 'https://openalex.org/I118905719';

CREATE OR REPLACE VIEW exploded_concepts AS
SELECT
  w.id AS work_id,
  concept.id AS concept_id,
  concept.display_name AS concept_name,
  concept.level AS concept_level
FROM works w
LATERAL VIEW EXPLODE(w.concepts) concept AS concept;
--  get_json_object(concept, '$.id') AS concept_id,
--  get_json_object(concept, '$.display_name') AS concept_name,
--  get_json_object(concept, '$.level') AS concept_level

