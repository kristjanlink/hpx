# hpx

## Prerequisites

- git
- awscli

## Quickstart: Updating HPX Using CloudFormation

Place something like this in ~/.hpxenv.

``` bash
BRANCH=$(git rev-parse --abbrev-ref HEAD)
HPX_ROOT=s3://hpx-dev-us-west-2
HPX_VERSION=0.0.0${BRANCH//[^a-zA-Z0-9]/}
PREFIX=hpx${BRANCH//[^a-zA-Z0-9]/}
REDSHIFT_PASSWORD=**********
```

Then:

```./bin/hpx.sh deploy```


## Appendix: Setting up the AWS Cli

### Using Brew

```bash

brew install awscli

```

### Using pip

```bash

pip install awscli

```

### Setup AWS Credentials

```bash aws configure```

For region us-west-2 got the most testing, but if you run into problems with the others ones
open an issue.

### Test

```bash
aws sts get-caller-identity
```
