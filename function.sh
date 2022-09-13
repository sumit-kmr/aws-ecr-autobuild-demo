#!/bin/bash

function handler () {
    # echo "Echoing from shell script"
    # anypoint-cli cloudhub load-balancer list
    export AWS_ACCESS_KEY_ID=$1
    export AWS_SECRET_ACCESS_KEY=$2
    export AWS_DEFAULT_REGION=$3
    #aws s3 --region $3 ls --no-verify-ssl
    aws configure list
    #aws s3api get-object --bucket anypoint-dlb-cert-bucket --key test.txt /tmp/froms3.txt
    ls /usr/local/bin/
}