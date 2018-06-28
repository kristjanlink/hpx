#!/bin/bash
# ./create-change-set.sh <stack name>
BRANCH=`git rev-parse --abbrev-ref HEAD`
LUSER=`whoami`

aws cloudformation create-change-set --stack-name hpx-$BRANCH --template-url https://s3-us-west-2.amazonaws.com/hpx-code/$BRANCH/cloudformation/hpx.yaml --change-set-name hpx-manual-changeset-$LUSER
