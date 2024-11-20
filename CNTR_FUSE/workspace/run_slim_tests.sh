#!/bin/bash

mkdir -p ./slim_results


# Remove old results
docker exec slim-sqlite sh -c "rm -rf /var/lib/phoronix-test-suite/test-results/*"

# Install dependencies and test suite
docker exec slim-sqlite apt-get update
docker exec slim-sqlite apt-get install -y unzip curl
docker exec slim-sqlite phoronix-test-suite install pts/stream

# Run the test
docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2" --max-runs=1 --max-test-run-time=300
# We can also uses different testes like below (Not Required for now)
# docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2" --max-runs=1 --max-test-run-time=300
# docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2"
# docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2" --test-size=small
# docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2" --max-runs=1
# docker exec slim-sqlite phoronix-test-suite batch-run pts/stream --options="1,2" --quick

# Get the latest test result identifier
RESULT_ID=$(docker exec slim-sqlite ls /var/lib/phoronix-test-suite/test-results | tail -n 1)
echo "Using results directory: $RESULT_ID"

# Generate the HTML report
docker exec slim-sqlite phoronix-test-suite result-file-to-html $RESULT_ID

# Copy the generated HTML report to the host
docker cp slim-sqlite:/root/$RESULT_ID.html ./slim_results/

# Verify the copied HTML report
if [ -f "./slim_results/$RESULT_ID.html" ]; then
    echo "HTML report generated successfully: ./slim_results/$RESULT_ID.html"
else
    echo "Failed to generate HTML report."
fi