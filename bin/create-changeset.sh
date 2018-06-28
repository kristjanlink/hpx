#!/bin/bash
# ./create-change-set.sh <stack name>
BRANCH=`git rev-parse --abbrev-ref HEAD`
LUSER=`whoami`
ENVIRONMENT="prod"

if [ $BRANCH != "master" ]; then
  ENVIRONMENT="dev"
fi

echo "Creating changeset for stack hpx-$BRANCH"
echo "BRANCH=$BRANCH, ENVIRONMENT=$ENVIRONMENT"

aws cloudformation create-change-set \
  --stack-name hpx-$BRANCH \
  --template-url https://s3-us-west-2.amazonaws.com/hpx-code/$BRANCH/cloudformation/hpx.yaml \
  --change-set-name hpx-manual-changeset-$LUSER \
  --parameters \
ParameterKey=\"Environment\",\
ParameterValue=\"$ENVIRONMENT\",\
UsePreviousValue=false\
