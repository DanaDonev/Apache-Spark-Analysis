# Apache-Spark-Analysis
Bachelor’s Thesis – Analyzing a portion of OpenAlex data using Apache Spark SQL

## Steps to run it:
1. Download and open the folder with VScode
2. Change the file path in sql/query.sql
3. Open terminal and run: spark-sql -f sql/query.sql

## Extra functions for complex data (additional to the SQL ones):
| **Function**        | **Purpose**                                            | **Category**           |
| ------------------- | ------------------------------------------------------ | ---------------------- |
| `explode()`         | Expand an array into multiple rows                     | Spark Complex Types    |
| `posexplode()`      | Like `explode()`, with position/index                  | Spark Complex Types    |
| `from_json()`       | Convert JSON string to struct                          | JSON Functions         |
| `get_json_object()` | Extract specific field from JSON string                | JSON Functions         |
| `json_tuple()`      | Extract multiple fields from JSON string               | JSON Functions         |
| `inline()`          | Explode array of structs into rows + columns           | Spark Complex Types    |
| `size()`            | Count elements in an array                             | Spark Complex Types    |
| `array_contains()`  | Check for element in an array                          | Spark Complex Types    |
| `element_at()`      | Get array/map element by index/key                     | Spark Complex Types    |
| `transform()`       | Apply a function to each element in an array           | Higher-Order Functions |
| `filter()`          | Filter elements of an array based on a condition       | Higher-Order Functions |
| `exists()`          | Check if any element in an array satisfies a condition | Higher-Order Functions |
| `aggregate()`       | Aggregate elements of an array using a function        | Higher-Order Functions |
| `zip_with()`        | Combine two arrays element-wise using a function       | Higher-Order Functions |
| `map_filter()`      | Filter map entries based on a condition                | Higher-Order Functions |


## Data types (additional to the SQL: TINYINT, SMALLINT, INT, BIGINT, FLOAT, DOUBLE, DECIMAL, STRING, CHAR, VARCHAR, BOOLEAN, BINARY, DATE, TIMESTAMP, INTERVAL):
| **Type**   | **Brief Explanation**                                    | **Example**                      | **Functions**                                |
| ---------- | -------------------------------------------------------- | -------------------------------- | -------------------------------------------- |
| **ARRAY**  | **List of values of the same type (e.g., list of tags)** | `ARRAY<STRING>` → `["a", "b"]`   | `explode()`, `posexplode()`, `size()`        |
| **MAP**    | **Key-value pairs, useful when field names vary**        | `MAP<STRING, INT>`               | `map_keys()`, `map_values()`, `element_at()` |
| **STRUCT** | **Nested object, like a small table inside a column**    | `STRUCT<age: INT, city: STRING>` | **Dot notation (`.`)**, `inline()`           |
