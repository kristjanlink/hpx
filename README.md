# hpx

## Prerequisites
- git
- awscli

## Quickstart: Updating HPX Using CloudFormation

``` ~/.hpxenv
REDSHIFT_PASSWORD=**********

if [ ! -z ${PRODUCTION:-} ]; then
 HPX_ROOT=s3://hpx-release-us-west-2
 PREFIX=hpxmaster
else
 BRANCH=$(git rev-parse --abbrev-ref HEAD)
 HPX_ROOT=s3://hpx-dev-us-west-2
 HPX_VERSION=0.0.0${BRANCH//[^a-zA-Z0-9]/}
 PREFIX=hpx${BRANCH//[^a-zA-Z0-9]/}
fi
```

```./bin/hpx.sh deploy```
