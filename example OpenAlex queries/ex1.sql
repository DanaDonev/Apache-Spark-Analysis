-- 1. Preview the dataset
SELECT * FROM openalex_works LIMIT 10;

-- 2. Show schema info (indirectly, via sample data types)
DESCRIBE openalex_works;

-- 3. Filter works published in 2023 or later
CREATE OR REPLACE TEMP VIEW recent_works AS
SELECT id, title, publication_year, cited_by_count, type
FROM openalex_works
WHERE publication_year >= 2023;

-- 4. Cast cited_by_count to DOUBLE (if needed)
CREATE OR REPLACE TEMP VIEW works_casted AS
SELECT id, title, publication_year, CAST(cited_by_count AS DOUBLE) AS cited_by_count, type
FROM recent_works;

-- 5. Add a new column with adjusted citation score
CREATE OR REPLACE TEMP VIEW works_with_adjusted_score AS
SELECT *, cited_by_count + 10 AS adjusted_score
FROM works_casted;

-- 6. Update a column value (add bonus score)
CREATE OR REPLACE TEMP VIEW works_with_bonus_score AS
SELECT *, adjusted_score + 5 AS bonus_score
FROM works_with_adjusted_score;

-- 7. Drop a column
CREATE OR REPLACE TEMP VIEW works_dropped_score AS
SELECT id, title, publication_year, type, bonus_score
FROM works_with_bonus_score;

-- 8. Create a full_title column by concatenating title and type
CREATE OR REPLACE TEMP VIEW works_with_full_title AS
SELECT *, CONCAT(title, ' [', type, ']') AS full_title
FROM works_dropped_score;

-- 9. Add a CASE clause to classify by citation level
CREATE OR REPLACE TEMP VIEW works_with_impact AS
SELECT *,
  CASE
    WHEN bonus_score > 100 THEN 'High'
    WHEN bonus_score BETWEEN 20 AND 100 THEN 'Medium'
    ELSE 'Low'
  END AS impact_level
FROM works_with_full_title;

-- 10. Rename column (type -> work_type)
CREATE OR REPLACE TEMP VIEW renamed_columns AS
SELECT id, title, publication_year, bonus_score, impact_level, full_title, type AS work_type
FROM works_with_impact;

-- 11. Group and count works by type and impact
CREATE OR REPLACE TEMP VIEW summary_by_type AS
SELECT work_type, impact_level, COUNT(*) AS total
FROM renamed_columns
GROUP BY work_type, impact_level
ORDER BY total DESC;

-- 12. Count how many works were published each year
CREATE OR REPLACE TEMP VIEW yearly_counts AS
SELECT publication_year, COUNT(*) AS num_works
FROM openalex_works
GROUP BY publication_year
ORDER BY publication_year DESC;

-- 13. Show most common languages (if 'language' column exists)
CREATE OR REPLACE TEMP VIEW top_languages AS
SELECT language, COUNT(*) AS count
FROM openalex_works
GROUP BY language
ORDER BY count DESC
LIMIT 10;

-- 14. Save results to local CSV
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/openalex_output/csv'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT * FROM summary_by_type;

-- 15. Save results to local JSON
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/openalex_output/json'
STORED AS JSON
SELECT * FROM summary_by_type;

-- 16. Save results to local Parquet
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/openalex_output/parquet'
STORED AS PARQUET
SELECT * FROM summary_by_type;