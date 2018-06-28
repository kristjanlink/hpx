#!/bin/bash
# ./create-change-set.sh <name of stack> <name of change set>
aws cloudformation create-change-set --stack-name $1 --template-body file://hpx.yaml --change-set-name $1
