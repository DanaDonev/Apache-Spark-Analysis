#!/bin/bash

# Base paths
VIEWS_DIR="views"
QUERIES_DIR="queries"
RESULTS_DIR="results"

# Create results folder if missing
mkdir -p "$RESULTS_DIR"

echo "=== Step 1: Creating base view uni_works ==="
spark-sql -f "$VIEWS_DIR/create_uni_works.sql"

echo "=== Step 2: Running all queries ==="
# Loop through all .sql files
for sql_file in $(find "$QUERIES_DIR" -type f -name "*.sql"); do
    # Derive output path (replace queries/ with results/, change .sql to .csv)
    relative_path=${sql_file#"$QUERIES_DIR/"}   # strip prefix
    output_path="$RESULTS_DIR/${relative_path%.sql}.csv"

    # Create folder structure inside results/
    mkdir -p "$(dirname "$output_path")"

    echo "Running $sql_file -> $output_path"

    # Run Spark SQL and save output as CSV
    spark-sql -f "$sql_file" --output-format csv > "$output_path"
done

echo "=== All queries finished! Results are in $RESULTS_DIR ==="
