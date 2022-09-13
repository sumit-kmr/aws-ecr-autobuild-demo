#!/bin/bash

function handler () {
    # echo "Echoing from shell script"
    # anypoint-cli cloudhub load-balancer list
    export AWS_ACCESS_KEY_ID=$1
    export AWS_SECRET_ACCESS_KEY=$2
    export AWS_DEFAULT_REGION=$3
    echo '[user1]\naws_access_key_id=$1\naws_secret_access_key=$2' > /tmp/aws_credentials
    echo '[profile user1]\nregion=$3\noutput=json' > /tmp/aws_config
    export AWS_SHARED_CREDENTIALS_FILE=/tmp/aws_credentials
    export AWS_CONFIG_FILE=/tmp/aws_config
    export AWS_PROFILE=user1
    #aws configure list
    #aws s3 ls --no-verify-ssl --profile user1
    #aws s3api get-object --bucket anypoint-dlb-cert-bucket --key test.txt /tmp/froms3.txt
    ls /var/
    echo "-------"
    ls ~/
    find ~/ -d -name ".aws"
}