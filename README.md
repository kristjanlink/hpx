# hpx

## Prerequisites

Amazon command line tools (```awscli```) are required in order to use the HPX scripts. For details, see [Amazon's documentation](https://docs.aws.amazon.com/lambda/latest/dg/setup-awscli.html)

## Quickstart: Creating an HPX stack

From a bash prompt:
```bash
./dist/bin/hpx-deploy.sh
```

This will create a default stack and automatically configure each AWS Resource.

For information on how to customize your HPX stack, run:
```bash
./dist/bin/hpx-deploy.sh help
```

### Developing HPX

```
./bin/hpx.sh
```
This script contains the tools necessary to package and distribute hpx.
For usage details:
```bash
./bin/hpx.sh help
```

When developing hpx, we recommend use a separate root and prefixes for testing
non-release code. For example, the configuration below sets the prefix based on the current git
branch.

``` ~/.hpx/default
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
