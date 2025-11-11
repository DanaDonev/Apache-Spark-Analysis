WITH ranked AS (
  SELECT
    id,
    title,
    cited_by_count,
    PERCENT_RANK() OVER (ORDER BY cited_by_count DESC) AS rank
  FROM uni_works
)
SELECT *
FROM ranked
WHERE rank <= 0.01
ORDER BY cited_by_count DESC;
