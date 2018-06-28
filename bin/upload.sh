#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
aws s3 sync `dirname $DIR` s3://hpx-code-pipeline-repo-us-east-1/`git rev-parse --abbrev-ref HEAD` --delete
