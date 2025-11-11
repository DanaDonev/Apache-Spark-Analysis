--SELECT
--  i.display_name AS partner_institution,
--  COUNT(DISTINCT u.id) AS num_collaborations
--FROM uni_works u
--JOIN exploded_institutions i ON u.id = i.work_id
--WHERE i.institution_id != 'https://openalex.org/I118905719'
--GROUP BY i.display_name
--ORDER BY num_collaborations DESC
--LIMIT 20;

WITH partner_collaborations AS (
  SELECT
    i.display_name AS partner_institution,
    i.country_code,
    COUNT(DISTINCT u.id) AS num_collaborations
  FROM uni_works u
  JOIN exploded_institutions i
    ON u.id = i.work_id
  WHERE i.institution_id != 'https://openalex.org/I118905719'
  GROUP BY i.display_name, i.country_code
),

ranked_partners AS (
  SELECT *,
         PERCENT_RANK() OVER (ORDER BY num_collaborations DESC) AS pr
  FROM partner_collaborations
)

SELECT *
FROM ranked_partners
WHERE pr <= 0.8
ORDER BY num_collaborations DESC;

