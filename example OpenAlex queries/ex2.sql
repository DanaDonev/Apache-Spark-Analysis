-- Step 1: Preview the OpenAlex works table
SELECT * FROM openalex_works LIMIT 10;

-- Step 2: Filter works from the last 5 years with more than 10 citations
CREATE OR REPLACE TEMP VIEW recent_highly_cited AS
SELECT id, title, publication_year, cited_by_count, type
FROM openalex_works
WHERE publication_year >= 2020
  AND cited_by_count > 10;

-- Step 3: Add impact category (High, Medium, Low)
CREATE OR REPLACE TEMP VIEW categorized_impact AS
SELECT *,
       CASE
         WHEN cited_by_count > 100 THEN 'High'
         WHEN cited_by_count BETWEEN 20 AND 100 THEN 'Medium'
         ELSE 'Low'
       END AS impact_level
FROM recent_highly_cited;

-- Step 4: Count works by type and impact
CREATE OR REPLACE TEMP VIEW type_impact_summary AS
SELECT type, impact_level, COUNT(*) AS total_works
FROM categorized_impact
GROUP BY type, impact_level
ORDER BY total_works DESC;

-- Step 5: Show top 10 rows of the summary
SELECT * FROM type_impact_summary LIMIT 10;

-- Step 6: Save summary to local directory as CSV
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/openalex_summary_output'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
SELECT * FROM type_impact_summary;