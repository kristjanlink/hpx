#!/bin/bash

set -u

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=`basename "${BASH_SOURCE[0]}"`
LUSER=`whoami`
CODE_BUCKET=""
. ${SCRIPTDIR}/../.env

REQUIRES=(PREFIX ENVIRONMENT REDSHIFT_PASSWORD VPC_CIDR)
for envvar in ${REQUIRES[@]}; do
  if [ -z ${!envvar} ]; then
    echo "${SCRIPTNAME}: ${envvar} not set!"
    RES="FAILED"
  fi
done

[[ $RES = "FAILED" ]] && exit 10

if [ -z `which aws` ]; then
  echo "${SCRIPTNAME}: AWS Cli not found!"
  exit 20
fi
REGION=`aws configure get region`

if [ -z $STACKNAME ]; then
  STACKNAME="$PREFIX-$ENVIRONMENT-$REGION"
fi


if ! aws cloudformation describe-stacks --stack-name $STACKNAME > /dev/null 2>&1; then
  echo "Creating new stack: $STACKNAME"
  AWSCOMMAND=create-stack
else
  echo "Creating changeset for existing stack: $STACKNAME"
  AWSCOMMAND=create-change-set
fi

echo aws cloudformation $AWSCOMMAND \
  --capabilities CAPABILITY_NAMED_IAM \
  --stack-name $STACKNAME \
  --template-url $TEMPLATE_URL \
  --change-set-name $PREFIX-changeset-$LUSER-$REGION \
  --parameters \
ParameterKey=\"Environment\",\
ParameterValue=\"$ENVIRONMENT\" \
ParameterKey=\"VpcCidrBlock\",\
ParameterValue=\"$VPC_CIDR\" \
ParameterKey=\"RedshiftPassword\",\
ParameterValue=\"$REDSHIFT_PASSWORD\"
