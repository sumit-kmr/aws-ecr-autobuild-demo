#!/bin/bash
cd /tmp

HEADERS="$(mktemp)"
# Get the lambda invocation event
EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")

# Extract request ID by scraping response headers received above
REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)

echo "request id: $REQUEST_ID"
echo "aws access key: $AWS_ACCESS_KEY"
echo "aws secret key: $AWS_SECRET_KEY"

# Download file from S3
./s3-get.sh  "anypoint-dlb-cert-bucket" "$AWS_REGION" "test.txt" "/tmp"

echo "Downloaded file content: "
cat /tmp/test.txt

# Send the response
curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response"  -d "response from fun"
