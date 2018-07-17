# hpx

This repo contains scripts that will quickly set up a simple data pipeline in AWS.
It will set up Cloudfront, Kinesis and Redshift to allow your
users to hit a pixel that will record their IP, User-agent and 4 custom parameters.

Grab the latest [release](https://github.com/TurboVentures/hpx/releases) here, or
clone this repo.

## Prerequisites

The scripts make extensive use of the Amazon command line tools
(`awscli`). If you don't have it installed and configured 
check out the [guide](#setup-awscli) below.

## Quickstart: Creating an HPX stack

To create the basic stack go into your terminal and change to the directory where
you cloned or downloaded the scripts.  From there it's a simple as running:

```bash
./dist/bin/hpx-deploy.sh
```

If all goes well, Amazon should be bringing up our default configuration for your
new data stack.  As it's chugging along (this can take up to an hour), you can check
if it's done using `./dist/bin/hpx-deploy.sh --status`, or follow along in the [AWS
console](https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2).

This stack should be able to handle 1000 QPS.

Your configuration will be available in ~/.hpx/default file.

For information on how to customize your HPX stack, run:

```bash
./dist/bin/hpx-deploy.sh help
```

## Design

The stack has a S3 backed CloudFront as the pixel server.  We played around with
using lambda edge on CloudFront as the pixel server, but using S3 was _much_ more stable
under load.  CloudFront is configured to dump its logs into a S3 bucket.  This will trigger a
lambda script that will parse the logs and send it to Kinesis Firehose.  Kinesis Firehose then
loads the data into Redshift.

If you want to further customize your stack or curious about how it all works, let's first 
take a quick tour of the directory structure. `src` is where the Lambda scripts live.  This includes
the one mentioned above that processes the log data, as well as the ones that are
used directly by CloudFormation to set up or configure the service.

`dist` contains the files that will be pushed into S3.  This includes the packaged lambdas, and s3 origin
files as well as the CloudFormation template, which is at `dist/cloudformation/hpx.yaml`.

`bin` contains the script that packages everything into the `dist`.  More about that in the next section.

## Developing HPX scripts

```bash
./bin/hpx.sh
```

This script contains the tools necessary to package and distribute hpx.
For usage details:
```bash
./bin/hpx.sh help
```

When developing hpx, we recommend use a separate root and prefixes for testing
non-release code. For example, the configuration (placed in `~/.hpx/default`) below 
sets the prefix based on the current git branch.

```bash
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

## Setup AWSCLI

### Installing the tools

If you are on MacOS and have [Homebrew](https://brew.sh/) installed,
the easiest thing to do is:

```bash

brew install awscli

```

Otherwise if you have Python PIP:

```bash

pip install awscli

```

If you don't fall into these categories check out Amazon's [install guide](https://docs.aws.amazon.com/cli/latest/userguide/installing.html).

### Setup AWS Credentials

```bash
aws configure
```

Since Cloudformation is setting up a lot of services, the credentials you pick should have a broad
set of privileges.  Each of the services will get a restricted set of roles that they actually run under.

For region us-west-2 got the most testing, but if you run into problems with the others ones
open an issue, or conversely drop us a line if you had success with a region.

### Testing your AWSCLI setup

This is a simple command that should tell you if you set up AWS-CLI correctly.  It will not check
if you have the necessary privileges to start the stack.

```bash
aws sts get-caller-identity
```
