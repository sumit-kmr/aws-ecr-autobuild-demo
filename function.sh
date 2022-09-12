#!/bin/bash

function handler () {
    echo "Echoing from shell script"
    anypoint-cli cloudhub load-balancer list
    aws s3 ls --no-verify-ssl
}