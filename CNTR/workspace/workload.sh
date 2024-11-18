#!/bin/bash
echo "Starting SQLite workload..."

sqlite3 /tmp/test.db <<EOF
DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id INTEGER PRIMARY KEY, value TEXT);
BEGIN TRANSACTION;
-- Insert 10,000 rows
INSERT INTO test_table (value) VALUES ('data1');
INSERT INTO test_table (value) VALUES ('data2');
INSERT INTO test_table (value) VALUES ('data3');
COMMIT;

-- Perform updates
BEGIN TRANSACTION;
UPDATE test_table SET value = 'updated_data' WHERE id % 3 = 0;
COMMIT;

-- Select to simulate read load
SELECT * FROM test_table;

-- Write to a file to simulate I/O
.output /tmp/sql_output.txt
SELECT * FROM test_table;
EOF

echo "SQLite workload completed."
