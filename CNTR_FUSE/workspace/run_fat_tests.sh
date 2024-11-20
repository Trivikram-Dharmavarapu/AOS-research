#!/bin/bash

# Ensure the results directory exists on the host
mkdir -p ./slim_fat_results

# Remove old results from slim
docker exec slim-sqlite sh -c "rm -rf /var/lib/phoronix-test-suite/test-results/*"

# Run the test in slim
docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2" --max-runs=1 --max-test-run-time=300

# Get the latest test result identifier
RESULT_ID=$(docker exec slim-sqlite ls /var/lib/phoronix-test-suite/test-results | tail -n 1)
echo "Using results directory: $RESULT_ID"

# Generate the HTML report in slim
docker exec slim-sqlite phoronix-test-suite result-file-to-html $RESULT_ID

# Copy the generated HTML report from slim to the host
docker cp slim-sqlite:/root/$RESULT_ID.html ./slim_fat_results/

# Verify the copied HTML report
if [ -f "./slim_fat_results/$RESULT_ID.html" ]; then
    echo "HTML report generated successfully: ./slim_fat_results/$RESULT_ID.html"
else
    echo "Failed to generate HTML report."
fi
