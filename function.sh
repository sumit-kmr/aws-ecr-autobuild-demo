#!/bin/bash

function handler () {
    echo "Echoing from shell script"
    # anypoint-cli cloudhub load-balancer list
    stringToSign="Sumit"
    AWS_SECRET_KEY=$2
    signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${AWS_SECRET_KEY} -binary | base64`
    echo $signature
}