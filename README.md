# Apache-Spark-Analysis
Bachelor’s Thesis – Analyzing a portion of OpenAlex data using Apache Spark SQL

## Steps to run it:
1. Download and open the folder with VScode
2. Change the file path in sql/query.sql
3. Open terminal and run: spark-sql -f sql/query.sql

## Extra functions for complex data (additional to the SQL ones):
| **Function**        | **Purpose**                                  |
| ------------------- | -------------------------------------------- |
| `explode()`         | Expand an array into multiple rows           |
| `posexplode()`      | Like `explode()`, with position/index        |
| `from_json()`       | Convert JSON string to struct                |
| `get_json_object()` | Extract specific field from JSON string      |
| `json_tuple()`      | Extract multiple fields from JSON string     |
| `inline()`          | Explode array of structs into rows + columns |
| `size()`            | Count elements in an array                   |
| `array_contains()`  | Check for element in array                   |
| `element_at()`      | Get array/map element by index/key           |

## Data types (additional to the SQL: TINYINT, SMALLINT, INT, BIGINT, FLOAT, DOUBLE, DECIMAL, STRING, CHAR, VARCHAR, BOOLEAN, BINARY, DATE, TIMESTAMP, INTERVAL):
| **Type**   | **Brief Explanation**                                    | **Example**                      |
| ---------- | -------------------------------------------------------- | -------------------------------- |
| **ARRAY**  | **List of values of the same type (e.g., list of tags)** | `ARRAY<STRING>` → `["a", "b"]`   |
| **MAP**    | **Key-value pairs, useful when field names vary**        | `MAP<STRING, INT>`               |
| **STRUCT** | **Nested object, like a small table inside a column**    | `STRUCT<age: INT, city: STRING>` |
