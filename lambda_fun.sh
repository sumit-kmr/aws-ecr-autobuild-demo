#!/bin/bash
cd /tmp

HEADERS="$(mktemp)"
# Get the lambda invocation event
EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
# Extract request ID by scraping response headers received above
REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)
# Declare constants
CURRENT_DATE_DAY="$(date -u '+%Y%m%d')"
CURRENT_DATE_ISO8601="${CURRENT_DATE_DAY}T$(date -u '+%H%M%S')Z"
EMPTY_STRING_HASH="$(printf "" | openssl dgst -sha256 | sed 's/^.* //')"
AWS_SERVICE='s3'
AWS_S3_BUCKET_NAME='anypoint-dlb-cert-bucket'

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

# Create the signature.
# Usage:
#   create_signature <canonical_request>
function create_signature {
    stringToSign="AWS4-HMAC-SHA256\n${CURRENT_DATE_ISO8601}\n${CURRENT_DATE_DAY}/${AWS_REGION}/${AWS_SERVICE}/aws4_request\n$(hash_sha256 "${1}")"
    dateKey=$(hmac_sha256 key:"AWS4${AWS_SECRET_KEY}" "${CURRENT_DATE_DAY}")
    regionKey=$(hmac_sha256 hexkey:"${dateKey}" "${AWS_REGION}")
    serviceKey=$(hmac_sha256 hexkey:"${regionKey}" "${AWS_SERVICE}")
    signingKey=$(hmac_sha256 hexkey:"${serviceKey}" "aws4_request")

    printf "${stringToSign}" | openssl dgst -sha256 -mac HMAC -macopt hexkey:"${signingKey}" | sed 's/(stdin)= //'
}

# Download the file from S3.
# Usage:
#   download_s3_file <s3_object_key> <output_path>
function download_s3_file {
    AWS_S3_PATH="$(echo $1 | sed 's;^\([^/]\);/\1;')"
    AWS_SERVICE_ENDPOINT_URL="${AWS_SERVICE}.${AWS_REGION}.amazonaws.com"
    HTTP_CANONICAL_REQUEST_URI="/${AWS_S3_BUCKET_NAME}${AWS_S3_PATH}"
    HTTP_REQUEST_CONTENT_TYPE='application/octet-stream'
    HTTP_CANONICAL_REQUEST_HEADERS="content-type:${HTTP_REQUEST_CONTENT_TYPE}
host:${AWS_SERVICE_ENDPOINT_URL}
x-amz-content-sha256:${EMPTY_STRING_HASH}
x-amz-date:${CURRENT_DATE_ISO8601}"
    # Note: The signed headers must match the canonical request headers.
    HTTP_REQUEST_SIGNED_HEADERS="content-type;host;x-amz-content-sha256;x-amz-date"
    HTTP_CANONICAL_REQUEST="GET
${HTTP_CANONICAL_REQUEST_URI}\n
${HTTP_CANONICAL_REQUEST_HEADERS}\n
${HTTP_REQUEST_SIGNED_HEADERS}
${EMPTY_STRING_HASH}"
    SIGNATURE="$(create_signature "${HTTP_CANONICAL_REQUEST}" | tail -c 65)"
    HTTP_REQUEST_AUTHORIZATION_HEADER="\
    AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY}/${CURRENT_DATE_DAY}/\
    ${AWS_REGION}/${AWS_SERVICE}/aws4_request, \
    SignedHeaders=${HTTP_REQUEST_SIGNED_HEADERS}, Signature=${SIGNATURE}"

    [ -d $2 ] && OUT_FILE="$2/$(basename $AWS_S3_PATH)" || OUT_FILE=$2
    curl "https://${AWS_SERVICE_ENDPOINT_URL}${HTTP_CANONICAL_REQUEST_URI}" \
        -H "Authorization: ${HTTP_REQUEST_AUTHORIZATION_HEADER}" \
        -H "content-type: ${HTTP_REQUEST_CONTENT_TYPE}" \
        -H "x-amz-content-sha256: ${EMPTY_STRING_HASH}" \
        -H "x-amz-date: ${CURRENT_DATE_ISO8601}" \
        -f -S -o ${OUT_FILE}
}

download_s3_file "test.txt" "/tmp"

echo "Downloaded file content: "
cat /tmp/test.txt