#!/bin/bash

function handler () {
    # echo "Echoing from shell script"
    # anypoint-cli cloudhub load-balancer list
    # aws configure import --csv "file://~/aws_credentials.csv"
    export AWS_ACCESS_KEY_ID=$1
    export AWS_SECRET_ACCESS_KEY=$2
    export AWS_DEFAULT_REGION=$3
    #aws s3 --region $3 ls --no-verify-ssl
    aws configure list
}