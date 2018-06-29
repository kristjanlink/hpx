#!/bin/bash
# ./create-change-set.sh <stack name>
BRANCH=`git rev-parse --abbrev-ref HEAD`
LUSER=`whoami`
ENVIRONMENT="prod"
REGION=`aws configure get region`

if [ -z $REDSHIFT_PASSWORD ]; then
  echo "You must set environment variable REDSHIFT_PASSWORD to proceed!"
  exit
fi

if [ $BRANCH != "master" ]; then
  ENVIRONMENT=$BRANCH
fi

echo "Creating changeset for stack hpx-$BRANCH"
echo "BRANCH=$BRANCH, ENVIRONMENT=$ENVIRONMENT"
echo "You are in region $REGION"


#aws cloudformation create-change-set \
#  --capabilities CAPABILITY_NAMED_IAM \
#  --stack-name hpx-secureparam-$BRANCH-$REGION \
#  --template-url https://s3-$REGION.amazonaws.com/hpx-code/$BRANCH/cloudformation/hpx-secureparam.yaml \
#  --change-set-name hpx-secureparam-manual-changeset-$LUSER-$REGION

aws cloudformation create-change-set \
  --capabilities CAPABILITY_NAMED_IAM \
  --stack-name hpx-$BRANCH-$REGION \
  --template-url https://s3-$REGION.amazonaws.com/hpx-code/$BRANCH/cloudformation/hpx.yaml \
  --change-set-name hpx-manual-changeset-$LUSER-$REGION \
  --parameters \
ParameterKey=\"Environment\",\
ParameterValue=\"$ENVIRONMENT\",\
UsePreviousValue=false,\
ParameterKey=\"RedShiftPassword\",\
ParameterValue=\"$REDSHIFT_PASSWORD\"\
