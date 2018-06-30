#!/bin/bash
# ./create-change-set.sh <stack name>
BRANCH=`git rev-parse --abbrev-ref HEAD`
LUSER=`whoami`
ENVIRONMENT=${BRANCH//[^a-zA-Z0-9]/}
REGION=`aws configure get region`

if [ -z $REDSHIFT_PASSWORD ]; then
  echo "You must set environment variable REDSHIFT_PASSWORD to proceed!"
  exit
fi


echo "BRANCH=$BRANCH, ENVIRONMENT=$ENVIRONMENT, REGION=$REGION"
echo "Creating changeset for stack hpx-$ENVIRONMENT-$REGION"

#aws cloudformation create-change-set \
#  --capabilities CAPABILITY_NAMED_IAM \
#  --stack-name hpx-secureparam-$ENVIRONMENT-$REGION \
#  --template-url https://s3-$REGION.amazonaws.com/hpx-code/$ENVIRONMENT/cloudformation/hpx-secureparam.yaml \
#  --change-set-name hpx-secureparam-manual-changeset-$LUSER-$REGION

aws cloudformation create-change-set \
  --capabilities CAPABILITY_NAMED_IAM \
  --stack-name hpx-$ENVIRONMENT-$REGION \
  --template-url https://s3-$REGION.amazonaws.com/hpx-code/$ENVIRONMENT/cloudformation/hpx.yaml \
  --change-set-name hpx-manual-changeset-$LUSER-$REGION \
  --parameters \
ParameterKey=\"Environment\",\
ParameterValue=\"$ENVIRONMENT\" \
ParameterKey=\"RedshiftPassword\",\
ParameterValue=\"$REDSHIFT_PASSWORD\"\
