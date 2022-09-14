#!/bin/bash

function handler () {
    npm install crypto-js
    echo "Echoing from shell script"
    echo "$AWS_LAMBDA_RUNTIME_API"
    echo "$REQUEST_ID"
    # anypoint-cli cloudhub load-balancer list
    # stringToSign="Sumit"
    # AWS_SECRET_KEY=$2
    # signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${AWS_SECRET_KEY} -binary | base64`
    # echo $signature
    node -e "var crypto = require('crypto-js');function getSignatureKey(key='$2', dateStamp='20220914', regionName='$3', serviceName='s3') {var kDate = crypto.HmacSHA256(dateStamp, 'AWS4' + key);var kRegion = crypto.HmacSHA256(regionName, kDate);var kService = crypto.HmacSHA256(serviceName, kRegion);var kSigning = crypto.HmacSHA256('aws4_request', kService);return kSigning;}console.log(getSignatureKey());"
}