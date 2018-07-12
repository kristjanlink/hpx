#!/bin/bash
set -u
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=`basename "${BASH_SOURCE[0]}"`
HPXDIR="$(dirname "$SCRIPTDIR" )"

RELEASEBUCKET=${RELEASEBUCKET:-"hpx-release-us-west-2"}
DEVBUCKET=${DEVBUCKET:-"hpx-dev-us-west-2"}
DRYRUN=${DRYRUN:+--dryrun}

usage() {
    cat 1>&2 <<EOF
hpx build 1.0.0

USAGE:
  hpx [package|dist|help] [OPTIONS]

COMMANDS:
  pack, package           Build and package the source directories
  dist                    Upload packaged files to S3
  help                    Print this message

OPTIONS:
  -r,--release <version>  Sets the release version for packaging. If set,
                          packages will be uploaded to the release bucket,
                          otherwise packages will be uploaded to the development
                          bucket using the current branch name as the version.
EOF
}

main() {
  [ -z `which aws` ] && err "AWS Cli not found!"
  REGION=`aws configure get region`

  SUBCOMMAND=${1:-help}; shift
  case "$SUBCOMMAND" in
    pack|package)
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

  info "Uploading to s3://$DISTBUCKET/$VERSION"
  aws s3 sync $HPXDIR/dist s3://$DISTBUCKET/$VERSION \
    --delete \
    --exclude .git/\* \
    --exclude .gitignore \
    --exclude .env \
    $DRYRUN
}

latest_version() {
  aws s3 cp s3://$RELEASEBUCKET/LATEST - 2> /dev/null
}

validate_version() {
  [ -z ${1:-} ] && err "Missing version string!"
  [[ ! $1 =~ ^[0-9]+\.[0-9]+(\.[0-9]+)*$ ]] && err "Version must match format #.#<.#>!"
}

info() {
  printf "[${SCRIPTNAME}] INFO: $1\n"
}

err() {
  printf "[${SCRIPTNAME}] ERROR: ${1:-Unknown Error!}\n\n"
  usage
  exit ${2:--1}
}


main "$@" || exit 1
