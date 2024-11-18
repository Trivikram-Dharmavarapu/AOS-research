#!/bin/bash

# SQLite workload script
echo "Starting SQLite workload..."

sqlite3 /tmp/test.db <<EOF
CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, value TEXT);
BEGIN TRANSACTION;
INSERT INTO test (value) VALUES ('data1'), ('data2'), ('data3');
UPDATE test SET value = 'updated_data' WHERE id = 2;
DELETE FROM test WHERE id = 3;
COMMIT;
EOF

echo "SQLite workload completed."
