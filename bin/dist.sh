#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HPXDIR=`dirname $SCRIPTDIR`
BRANCH=`git rev-parse --abbrev-ref HEAD`
ENVIRONMENT=${BRANCH//[^a-zA-Z0-9]/}

cd $HPXDIR
mkdir -p ./dist
[ -a "./dist/hpx.zip" ] && rm ./dist/hpx.zip

zip -q -r hpx . -x ./dist/\* -x .git/\* -x .gitignore -x ./src/\*
mv hpx.zip ./dist

aws s3 sync $HPXDIR s3://hpx-code/$ENVIRONMENT \
  --delete \
  --exclude .git/\* \
  --exclude .gitignore \
  --exclude src/\* \
