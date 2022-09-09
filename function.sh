#!/bin/bash


#anypoint-cli cloudhub load-balancer list
# Handler function name must match the
# last part of <fileName>.<handlerName>
function handler () {
    echo "Echoing from shell script"
    anypoint-cli cloudhub load-balancer list
}