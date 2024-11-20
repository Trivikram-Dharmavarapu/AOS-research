#!/bin/bash

# Create results directory
mkdir -p ./slim_results

# Clean up old results
docker exec slim-container sh -c "rm -rf /var/lib/phoronix-test-suite/test-results/*"

# Update Phoronix Test Suite
docker exec slim-container apt-get update
docker exec slim-container apt-get install -y unzip curl
docker exec slim-container phoronix-test-suite install pts/stream

# Run the test
docker exec slim-container phoronix-test-suite batch-run pts/stream --options="1,2" --max-runs=1 --max-test-run-time=300

# Get the latest test result identifier
RESULT_ID=$(docker exec slim-container ls /var/lib/phoronix-test-suite/test-results | tail -n 1)
if [ -z "$RESULT_ID" ]; then
    echo "No test results found. Test might have failed."
    exit 1
fi
echo "Using results directory: $RESULT_ID"

# Generate the HTML report
docker exec slim-container phoronix-test-suite result-file-to-html $RESULT_ID

# Copy the generated HTML report to the host
docker cp slim-container:/var/lib/phoronix-test-suite/test-results/$RESULT_ID/$RESULT_ID.html ./slim_results/

# Verify the copied HTML report
if [ -f "./slim_results/$RESULT_ID.html" ]; then
    echo "HTML report generated successfully: ./slim_results/$RESULT_ID.html"
else
    echo "Failed to generate HTML report."
    exit 1
fi
