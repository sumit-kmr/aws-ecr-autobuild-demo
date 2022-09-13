#!/bin/bash

function handler () {
    # echo "Echoing from shell script"
    # anypoint-cli cloudhub load-balancer list
    # aws configure import --csv "file://~/aws_credentials.csv"
    # aws s3 ls --no-verify-ssl
    AWS_ACCESS_KEY=$1
    AWS_SECRET_KEY=$2
    AWS_REGION=$3
    echo "$AWS_ACCESS_KEY"
    echo "$AWS_SECRET_KEY"
    echo "$AWS_REGION"
}