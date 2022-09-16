#!/bin/bash

HEADERS="$(mktemp)"
# Get the lambda invocation event
EVENT_DATA=$(curl -sS -LD "$HEADERS" -X GET "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/next")
# Extract request ID by scraping response headers received above
REQUEST_ID=$(grep -Fi Lambda-Runtime-Aws-Request-Id "$HEADERS" | tr -d '[:space:]' | cut -d: -f2)
cd ~/
ls
cd /tmp
ls
# Declare constants
CURRENT_DATE_DAY="$(date -u '+%Y%m%d')"
CURRENT_DATE_ISO8601="${CURRENT_DATE_DAY}T$(date -u '+%H%M%S')Z"
EMPTY_STRING_HASH="$(printf "" | openssl dgst -sha256 | sed 's/^.* //')"
AWS_SERVICE='s3'
AWS_S3_BUCKET_NAME='anypoint-dlb-cert-bucket'
ANYPOINT_DLB_NAME='wdapi-sbx-dlb-us-west'
declare -a s3_keys # declare array

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

# List files from s3 folder.
# Usage:
#   list_s3_files <folder_name>
function list_s3_files {
  AWS_SERVICE_ENDPOINT_URL="${AWS_S3_BUCKET_NAME}.${AWS_SERVICE}.${AWS_REGION}.amazonaws.com"
	HTTP_CANONICAL_REQUEST_URI="/"
	HTTP_CANONICAL_QUERY_STRING="list-type=2&prefix=${1}"
	HTTP_CANONICAL_REQUEST_HEADERS="host:${AWS_SERVICE_ENDPOINT_URL}
x-amz-content-sha256:${EMPTY_STRING_HASH}
x-amz-date:${CURRENT_DATE_ISO8601}"
	HTTP_REQUEST_SIGNED_HEADERS="host;x-amz-content-sha256;x-amz-date"
	HTTP_CANONICAL_REQUEST="GET
${HTTP_CANONICAL_REQUEST_URI}
${HTTP_CANONICAL_QUERY_STRING}
${HTTP_CANONICAL_REQUEST_HEADERS}\n
${HTTP_REQUEST_SIGNED_HEADERS}
${EMPTY_STRING_HASH}"
	SIGNATURE="$(create_signature "${HTTP_CANONICAL_REQUEST}" | tail -c 65)"
  HTTP_REQUEST_AUTHORIZATION_HEADER="\
AWS4-HMAC-SHA256 Credential=${AWS_ACCESS_KEY}/${CURRENT_DATE_DAY}/\
${AWS_REGION}/${AWS_SERVICE}/aws4_request, \
SignedHeaders=${HTTP_REQUEST_SIGNED_HEADERS}, Signature=${SIGNATURE}"

  temp_xml_file="lists3resp.xml"
  curl "https://${AWS_SERVICE_ENDPOINT_URL}${HTTP_CANONICAL_REQUEST_URI}?${HTTP_CANONICAL_QUERY_STRING}" \
    -H "Authorization: ${HTTP_REQUEST_AUTHORIZATION_HEADER}" \
    -H "x-amz-content-sha256: ${EMPTY_STRING_HASH}" \
    -H "x-amz-date: ${CURRENT_DATE_ISO8601}" \
    -k -sS -o ${temp_xml_file}
	
	
  read_xml () { local IFS=\> ; read -d \< TAG VALUE ;}

  s3_keys=()
  i=0
  while read_xml; do
    if [[ $TAG == "Key" && $VALUE != "${1}/" ]]; then
      s3_keys[i++]=$VALUE
      fi
  done < $temp_xml_file
  rm $temp_xml_file
}


mkdir temp

# Download all ca-certs in a temp folder
echo "\nDownloading client certificates...\n"
#list_s3_files "ca-certs"
for s3_key in "${s3_keys[@]}"
do
	file_name=${s3_key##*/}
	download_s3_file "${s3_key}" "temp/${file_name}"
  echo "Downloaded: ${file_name}"
done

# Merge ca certs
echo "\nMerging the certificates...\n"
merged_certs_name="bundle.pem"
cat temp/* > ${merged_certs_name}
rm temp/*
mv ${merged_certs_name} temp/${merged_certs_name}

# Download dlb cert and private key
echo "\nDownloading DLB certificate and private key...\n"
cert_file_name="public.pem"
private_key_file_name="private.pem"
#list_s3_files "dlb-cert"
for s3_key in "${s3_keys[@]}"
do
	file_name=${s3_key##*/}
	if [[ $file_name == *"public"* ]]; then
		download_s3_file "${s3_key}" "temp/$cert_file_name"
	else
		download_s3_file "${s3_key}" "temp/$private_key_file_name"
	fi
  echo "Downloaded: ${file_name}"
done

# Get common name of the certificate
# cert_name=$(openssl x509 -noout -subject -in temp/$cert_file_name)
# cert_name=$(echo "${cert_name##*=}" | xargs)

# Replace the certificate
# echo "\nDeleting cert ${cert_name}..."
# anypoint-cli cloudhub load-balancer ssl-endpoint remove ${ANYPOINT_DLB_NAME} ${cert_name}
# echo "Uploading updated cert ${cert_name}..."
# anypoint-cli cloudhub load-balancer ssl-endpoint add --clientCertificate "temp/${merged_certs_name}" --verificationMode on $ANYPOINT_DLB_NAME "temp/${cert_file_name}" "temp/${private_key_file_name}" 
# echo "Setting ${cert_name} as default certificate..."
# anypoint-cli cloudhub load-balancer ssl-endpoint set-default $ANYPOINT_DLB_NAME $cert_name
# echo "\nCertificate replaced successfully!"

rm -r temp

# Send the response
curl -X POST "http://${AWS_LAMBDA_RUNTIME_API}/2018-06-01/runtime/invocation/$REQUEST_ID/response" -d "response from fun"