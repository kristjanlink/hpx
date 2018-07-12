#!/bin/bash
set -u
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=`basename "${BASH_SOURCE[0]}"`
HPXDIR="$(dirname "$SCRIPTDIR" )"

RELEASEBUCKET=${RELEASEBUCKET:-hpx-release-us-west-2}
DEVBUCKET=${DEVBUCKET:-hpx-dev-us-west-2}
DRYRUN=${DRYRUN:+--dryrun}

[ -z `which aws` ] && err "AWS Cli not found!"
REGION=`aws configure get region`

usage() {
    cat 1>&2 <<EOF
hpx build 1.0.0

USAGE:
  hpx [package|dist|help] [OPTIONS]

COMMANDS:
  package                 build and package the source directories
  dist                    upload packaged files to S3
  help                    print this message

OPTIONS:
  -r,--release <version>  Sets the release version for packaging. If set,
                          packages will be uploaded to the release bucket,
                          otherwise packages will be uploaded to the development
                          bucket using the current branch name as the version.
EOF
}

main() {
  SUBCOMMAND=${1:-help}; shift
  case "$SUBCOMMAND" in
    package)
      package $@
      ;;
    dist)
      dist $@
      ;;
    *)
      usage
  esac
}

package() {
  for custom_resource in $HPXDIR/src/custom_resources/*/; do
    pushd ${custom_resource}
    npm install
    npm run package
    popd
  done
}

dist() {
  case "${1:---development}" in
    -r|--release)
      DISTBUCKET=$RELEASEBUCKET
      VERSION=${2:-}
      validate_version $VERSION
      ;;
    *)
      DISTBUCKET=$DEVBUCKET
      [ -z `which git` ] && err "Git not found!"
      VERSION=`git rev-parse --abbrev-ref HEAD`
      [ -z $VERSION ] && err "Could not determine development BRANCH!"
      ;;
  esac
  aws s3 sync $HPXDIR/dist s3://$DISTBUCKET/$VERSION \
    --delete \
    --exclude .git/\* \
    --exclude .gitignore \
    --exclude .env \
    $DRYRUN

  echo "$VERSION" | aws s3 cp - s3://$DISTBUCKET/LATEST $DRYRUN
}

validate_version() {
  [ -z ${1:-} ] && err "Missing version string!"
  [[ ! $1 =~ ^[0-9]+\.[0-9]+(\.[0-9]+)*$ ]] && err "Version must match format #.#<.#>!"
}

err() {
  echo "${SCRIPTNAME}: ${1:-Unknown Error!}"
  usage
  exit ${2:--1}
}


main "$@" || exit 1
