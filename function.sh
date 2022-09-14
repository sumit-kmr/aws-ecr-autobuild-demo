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

# Usage:
#   s3-get.sh <bucket> <region> <source-file> <dest-path>
function s3-get {
    set -e

    script="${0##*/}"
    usage="USAGE: $script <bucket> <region> <source-file> <dest-path>
Example: $script dev.build.artifacts us-east-1 /jobs/dev-job/1/dist.zip ./dist.zip"

    [ $# -ne 4 ] && printf "ERROR: Not enough arguments passed.\n\n$usage\n" && exit 1

    [ -z "$AWS_ACCESS_KEY" -o -z "$AWS_SECRET_KEY" ] &&
        printf "ERROR: AWS_ACCESS_KEY and AWS_SECRET_KEY environment variables must be defined.\n" && exit 1

    [ ! type openssl ] 2>/dev/null && echo "openssl is required and must be installed" && exit 1
    [ ! type curl ] 2>/dev/null && echo "curl is required and must be installed" && exit 1

    AWS_SERVICE='s3'
    AWS_REGION="$2"
    AWS_SERVICE_ENDPOINT_URL="${AWS_SERVICE}.${AWS_REGION}.amazonaws.com"
    AWS_S3_BUCKET_NAME="$1"
    AWS_S3_PATH="$(echo $3 | sed 's;^\([^/]\);/\1;')"

    # Create an SHA-256 hash in hexadecimal.
    # Usage:
    #   hash_sha256 <string>
    function hash_sha256 {
        printf "${1}" | openssl dgst -sha256 | sed 's/^.* //'
    }

    # Create an SHA-256 hmac in hexadecimal.
    # Usage:
    #   hmac_sha256 <key> <data>
    function hmac_sha256 {
        printf "${2}" | openssl dgst -sha256 -mac HMAC -macopt "${1}" | sed 's/^.* //'
    }

    CURRENT_DATE_DAY="$(date -u '+%Y%m%d')"
    CURRENT_DATE_ISO8601="${CURRENT_DATE_DAY}T$(date -u '+%H%M%S')Z"

    HTTP_REQUEST_PAYLOAD_HASH="$(printf "" | openssl dgst -sha256 | sed 's/^.* //')"
    HTTP_CANONICAL_REQUEST_URI="/${AWS_S3_BUCKET_NAME}${AWS_S3_PATH}"
    HTTP_REQUEST_CONTENT_TYPE='application/octet-stream'

    HTTP_CANONICAL_REQUEST_HEADERS="content-type:${HTTP_REQUEST_CONTENT_TYPE}
host:${AWS_SERVICE_ENDPOINT_URL}
x-amz-content-sha256:${HTTP_REQUEST_PAYLOAD_HASH}
x-amz-date:${CURRENT_DATE_ISO8601}"
    # Note: The signed headers must match the canonical request headers.
    HTTP_REQUEST_SIGNED_HEADERS="content-type;host;x-amz-content-sha256;x-amz-date"
    HTTP_CANONICAL_REQUEST="GET
${HTTP_CANONICAL_REQUEST_URI}\n
${HTTP_CANONICAL_REQUEST_HEADERS}\n
${HTTP_REQUEST_SIGNED_HEADERS}
${HTTP_REQUEST_PAYLOAD_HASH}"

    # Create the signature.
    # Usage:
    #   create_signature
    function create_signature {
        stringToSign="AWS4-HMAC-SHA256\n${CURRENT_DATE_ISO8601}\n${CURRENT_DATE_DAY}/${AWS_REGION}/${AWS_SERVICE}/aws4_request\n$(hash_sha256 "${HTTP_CANONICAL_REQUEST}")"
        dateKey=$(hmac_sha256 key:"AWS4${AWS_SECRET_KEY}" "${CURRENT_DATE_DAY}")
        regionKey=$(hmac_sha256 hexkey:"${dateKey}" "${AWS_REGION}")
        serviceKey=$(hmac_sha256 hexkey:"${regionKey}" "${AWS_SERVICE}")
        signingKey=$(hmac_sha256 hexkey:"${serviceKey}" "aws4_request")

        printf "${stringToSign}" | openssl dgst -sha256 -mac HMAC -macopt hexkey:"${signingKey}" | sed 's/(stdin)= //'
    }

    SIGNATURE="$(create_signature)"
    HTTP_REQUEST_AUTHORIZATION_HEADER="\
AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY}/${CURRENT_DATE_DAY}/\
${AWS_REGION}/${AWS_SERVICE}/aws4_request, \
SignedHeaders=${HTTP_REQUEST_SIGNED_HEADERS}, Signature=${SIGNATURE}"

    [ -d $4 ] && OUT_FILE="$4/$(basename $AWS_S3_PATH)" || OUT_FILE=$4
    echo "s3-get CURRENT_DATE_ISO8601: $CURRENT_DATE_ISO8601"
    echo "s3-get AWS_ACCESS_KEY: ${AWS_ACCESS_KEY}"
    echo "s3-get AWS_SECRET_KEY: ${AWS_SECRET_KEY}"
    echo "s3-get AWS_REGION: ${AWS_REGION}"
    echo "Downloading https://${AWS_SERVICE_ENDPOINT_URL}${HTTP_CANONICAL_REQUEST_URI} to $OUT_FILE"

    curl "https://${AWS_SERVICE_ENDPOINT_URL}${HTTP_CANONICAL_REQUEST_URI}" \
        -H "Authorization: ${HTTP_REQUEST_AUTHORIZATION_HEADER}" \
        -H "content-type: ${HTTP_REQUEST_CONTENT_TYPE}" \
        -H "x-amz-content-sha256: ${HTTP_REQUEST_PAYLOAD_HASH}" \
        -H "x-amz-date: ${CURRENT_DATE_ISO8601}" \
        -f -S -o ${OUT_FILE}
}

# Download file from S3
s3-get "anypoint-dlb-cert-bucket" "$AWS_REGION" "test.txt" "/tmp"

echo "Downloaded file content: "
cat /tmp/test.txt

# Send the response
curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response" -d "response from fun"
