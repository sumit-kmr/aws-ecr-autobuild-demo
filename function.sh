#!/bin/bash

function handler () {
    echo "Echoing from shell script"
    anypoint-cli cloudhub load-balancer list
    aws configure import --csv "file://~/aws_credentials.csv"
    aws s3 ls --no-verify-ssl
}