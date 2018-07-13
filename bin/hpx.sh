#!/bin/bash
set -u
[ -f "$HOME/.hpxenv" ] && source "$HOME/.hpxenv"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
HPXDIR="$(dirname "$SCRIPTDIR" )"
DRYRUN=${DRYRUN:+--dryrun}

usage() {
    cat 1>&2 <<EOF
hpx build 1.0.0

USAGE:
  hpx [package|dist|help] [OPTIONS]

COMMANDS:
  pack, package             Build and package the source directories
  dist                      Upload packaged files to S3
  deploy                    Deploy the latest distribution
  help                      Print this message

OPTIONS:
  -V,--version <version>    Set the package version

                            [dist] Required unless HPX_VERSION is set
                            [deploy] Optional
                            If not set, the LATEST version will be deployed
                            (determined by inspecting <root>/LATEST)

  -R,--root  <s3uri>        Set the package root

                            [dist] Required unless HPX_ROOT is set
                            [deploy] Optional
                            Defaults to s3://hpx-release-us-west-2


ENVIRONMENT VARIABLES:
  HPX_ROOT                  Default root to use if '--root' is not specified
  HPX_VERSION               Default version to use if '--version' is not
                            specified


EOF
}

main() {
  [ -z $(which aws) ] && err "AWS Cli not found!"
  REGION=$(aws configure get region)

  SUBCOMMAND=${1:-help}; shift

  while [[ $# > 0 ]]; do
    case "$1" in
      -V|--version)
        [ -z ${2:-} ] && err "(--version) Version string expected!"
        HPX_VERSION=$2; shift 2
        ;;
      -R|--root)
        [ -z ${2:-} ] && err "(--root) Root S3URI expected!"
        HPX_ROOT=$2; shift 2
        ;;
      *)
        EXTRA_ARGS="${EXTRA_ARGS:-} $1"; shift
    esac
  done

  case "$SUBCOMMAND" in
    pack|package)
      package
      ;;
    dist)
      dist
      ;;
    deploy)
      HPX_ROOT=${HPX_ROOT:-"hpx-release-us-west-2"}
      deploy ${EXTRA_ARGS:-}
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
  validate_s3uri $HPX_ROOT
  validate_version $HPX_VERSION

  info "Uploading to $HPX_ROOT/$HPX_VERSION"
  aws s3 sync $HPXDIR/dist $HPX_ROOT/$HPX_VERSION \
    --delete \
    --exclude .git/\* \
    --exclude .gitignore \
    --exclude .hpxenv \
    $DRYRUN
}

deploy() {
  eval "$HPXDIR/dist/bin/hpx-deploy.sh -V $HPX_VERSION -R $HPX_ROOT ${1:-}"
}

latest_version() {
  aws s3 cp $HPX_ROOT/LATEST - 2> /dev/null
}

validate_s3uri() {
  [[ ! "$1" =~ ^s3://[a-zA-Z0-9.\-_]{1,255}/?.*$ ]] && err "Invalid S3URI ($1). S3URI must match ^s3://[a-zA-Z0-9.\-_]{1,255}/?.*$"
  ! aws s3 ls "$1" 2>&1 >/dev/null && err "Cannot access S3URI ($1)"
}

validate_version() {
  [ -z ${1:-} ] && err "Missing version string!"
  [[ ! $1 =~ ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$ ]] && err "Version ($1) must match format ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$"
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
