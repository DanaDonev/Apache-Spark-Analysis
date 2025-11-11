--work in one row per author per institution
CREATE OR REPLACE TEMP VIEW exploded_institutions AS
SELECT w.id AS work_id,
w.publication_year,
get_json_object(inst, '$.id') AS institution_id,
get_json_object(inst, '$.country_code') AS country_code,
get_json_object(inst, '$.display_name') AS display_name
FROM works w
LATERAL VIEW EXPLODE(w.authorships) auth AS auth_struct
LATERAL VIEW EXPLODE(auth_struct.institutions) inst AS inst;

--not optimized version of collaborations per institution SO BAD!
--SELECT i.display_name AS parther_institution, i.country_code, COUNT(DISTINCT w.id) AS num_collaborations
--FROM works w
--JOIN exploded_institutions i ON w.id = i.work_id
--WHERE i.institution_id != 'https://openalex.org/I118905719'
--AND EXISTS (SELECT 1
--FROM exploded_institutions ei
--WHERE ei.work_id = w.id
--AND ei.institution_id = 'https://openalex.org/I118905719')
--GROUP BY i.display_name, i.country_code
--ORDER BY num_collaborations DESC
--LIMIT 20;

--works from UP per year
SELECT w.publication_year, COUNT(DISTINCT w.id) AS num_works
FROM works w
JOIN exploded_institutions ei ON w.id = ei.work_id
WHERE ei.institution_id = 'https://openalex.org/I118905719'
AND w.publication_year IS NOT NULL
GROUP BY w.publication_year
ORDER BY w.publication_year;
