-- Create temporary view from JSON
CREATE OR REPLACE TEMP VIEW people USING json OPTIONS (path "C:/Users/Dana/Desktop/Apache-Spark-Analysis/mini analysis example/data/people.json");

-- Query the data
SELECT * FROM people;

-- Example query: Get names of people older than 28
SELECT name, age FROM people WHERE age > 28;

-- Example query: Count the number of people in each city
SELECT city, COUNT(*) AS count FROM people GROUP BY city;