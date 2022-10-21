#!/bin/bash

jsfile="`cat signature_v4_util.js`"
echo "JS File: $jsfile"
cd /tmp

echo "$jsfile" > signature_v4_util.js 

HEADERS="$(mktemp)"
# Get the lambda invocation event
EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
# Extract request ID by scraping response headers received above
REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)

creds="{\"accessKeyId\": \"${AWS_ACCESS_KEY}\" , \"secretAccessKey\" : \"${AWS_SECRET_KEY}\"}"

function get_secret {
  payload='{\"SecretId\": \"'"${1}"'\"}'
  opts="{
        \"host\": \"secretsmanager.ap-south-1.amazonaws.com\", 
        \"path\": \"/\", 
        \"service\": \"secretsmanager\", 
        \"region\": \"${AWS_REGION}\",
        \"headers\": {
                \"Content-Type\": \"application/x-amz-json-1.1\",
                \"X-Amz-Target\": \"secretsmanager.GetSecretValue\"
            },
        \"body\": \"$payload\"
    }"
  node signature_v4_util.js "get_secret" "$creds" "$opts"
  auth=$(sed -n "1 p" tempFile)
  date=$(sed -n "2 p" tempFile)
  rm tempFile
  temp_xml_file="response.json"
  curl --request POST "https://secretsmanager.ap-south-1.amazonaws.com" \
    -H "Authorization: ${auth}" \
    -H "x-amz-date: ${date}" \
    -H "content-type: application/x-amz-json-1.1" \
    -H "x-amz-target: secretsmanager.GetSecretValue" \
    --data-raw '{"SecretId": "'"${1}"'"}' \
    -k -sS -o ${temp_xml_file}

  node signature_v4_util.js "parse_secret"
  secret="`cat tempFile`"
  echo "Secret: $secret"
}

get_secret "example_secret"

# Send the response
curl -sS -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response" -d "Lambda function ran successfully"