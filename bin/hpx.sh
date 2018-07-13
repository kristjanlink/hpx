#!/bin/bash
set -u
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
HPXDIR="$(dirname "$SCRIPTDIR" )"

usage() {
    cat 1>&2 <<EOF
$SCRIPTNAME build 1.0.0

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

  -R,--root  <s3uri>        Set the root S3 dist location
                            EXAMPLE: 's3://hpx-dev-us-west-2'

                            [dist] Required unless HPX_ROOT is set
                            [deploy] Optional
                            Defaults to s3://hpx-release-us-west-2

  -C,--config               Use or create the specified configuration file.
                            Defaults to $HOME/.hpxenv if not set.

  -D,--dryrun               Does not dist or deploy HPX, but prints the
                            commands that will be called (ignored by package).

ENVIRONMENT VARIABLES:
  HPX_CFG_DIR                   Environment file to use unless --config
                            is specified. Defaults to ~/.hpxenv

  HPX_ROOT                  Root to use if '--root' is not specified

  HPX_VERSION               Version to use if '--version' is not
                            specified

FILES:
  ~/.hpxenv                 Configuration file used by HPX (~/.hpxenv unless
                            specified through HPX_CFG_DIR or --config). Use
                            this file to specify environment variables.
EOF
}

main() {
  [ -z $(which aws) ] && err "AWS Cli not found!"
  REGION=$(aws configure get region)

  SUBCOMMAND="${1:-}"; shift

  while [[ $# > 0 ]]; do
    case "$1" in
      -V|--version)
        HPX_VERSION="${2:-}"
        [ -z "$HPX_VERSION" ] && err "(--version) Version string expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -R|--root)
        HPX_ROOT="${2:-}"
        [ -z HPX_ROOT ] && err "(--root) Root S3URI expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -C|--config)
        HPX_CFG="${2:-}"
        [ -z "$HPX_CFG" ] && err "(--config) Filename expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -D|--dryrun)
        HPX_OPTIONS+=("$1")
        DRYRUN="| "
        shift
        ;;
      *)
        HPX_OPTIONS+=("$1")
        shift
    esac
  done

  HPX_CFG="${HPX_CFG:-"$HOME/.hpx/default"}"
  validate_hpx_cfg "$HPX_CFG"
  source "$HPX_CFG"

  case "$SUBCOMMAND" in
    pack|package)
      package
      ;;
    dist)
      dist
      ;;
    deploy)
      deploy "${HPX_OPTIONS[@]:-}"
      ;;
    *)
      usage
  esac
}

package() {
  for custom_resource in "$HPXDIR/src/custom_resources/*/"; do
    pushd "$custom_resource"
    npm install
    npm run package
    popd
  done
}

dist() {
  [ -z "${HPX_ROOT:-}" ] && err "Root destination must be set with --root or HPX_ROOT"
  validate_s3uri "$HPX_ROOT"

  [ -z "${HPX_VERSION:-}" ] && err "Version must be set with --version or HPX_VERSION"
  validate_version "$HPX_VERSION"

  info "Uploading to $HPX_ROOT/$HPX_VERSION"
  dryrun aws s3 sync "$HPXDIR/dist" "$HPX_ROOT/$HPX_VERSION" \
    --delete \
    --exclude \".git/*\" \
    --exclude .gitignore \
    --exclude .hpxenv
}

deploy() {
  eval "$HPXDIR/dist/bin/hpx-deploy.sh ${@:-}"
}

latest_version() {
  aws s3 cp "$HPX_ROOT/LATEST" - 2> /dev/null
}

validate_hpx_cfg() {
  mkdir -p "$(dirname "$1")"
  touch "$1"
  [ ! -r "$1" -a -w "$1" ] && err "Cannot access environment file ($1)!"
}

validate_s3uri() {
  [[ ! "$1" =~ ^s3://[a-zA-Z0-9.\-_]{1,255}/?.*$ ]] && err "Invalid S3URI ($1). S3URI must match ^s3://[a-zA-Z0-9.\-_]{1,255}/?.*$"
  ! aws s3 ls "$1" 2>&1 >/dev/null && err "Cannot access S3URI ($1)"
}

validate_version() {
  [ -z "${1:-}" ] && err "Missing version string!"
  [[ ! "$1" =~ ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$ ]] && err "Version ($1) must match format ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$"
}

info() {
  printf "[${SCRIPTNAME}] INFO: $1\n"
}

err() {
  printf "[${SCRIPTNAME}] ERROR: ${1:-Unknown Error!}\n\n"
  usage
  exit -1
}

dryrun() {
  if [ -n "$DRYRUN" ]; then
    printf "[${SCRIPTNAME}] DRYRUN:\n$DRYRUN"
    for line in "$@"; do
      if [[ "$line" =~ ^--.*$ ]]; then
        printf "\n$DRYRUN   $line"
      elif [[ "$line" =~ ^.{40,}$ ]]; then
        printf "\n$DRYRUN       $line"
      else
        printf " $line"
      fi
    done
    printf "\n\n"
  else
    eval "$@"
  fi
}

main "$@" || exit 1
