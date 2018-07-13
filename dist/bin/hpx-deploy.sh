#!/bin/bash
set -u
[ -f "$HOME/.hpxenv" ] && source "$HOME/.hpxenv"
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
LUSER=$(whoami)
HPX_ROOT=${HPX_ROOT:-"s3://hpx-release-us-west-2"}

usage() {
    cat 1>&2 <<EOF
cf-deploy build 1.0.0

USAGE:
  hpx-deploy [OPTIONS] <stack-name>

ARGUMENTS:
  stack-name                    Name of the stack you wish to create or update.
                                Defaults to "$PREFIX-<AWS REGION>"

OPTIONS:
  -V,--version <version>        Select the version of HPX to deploy.
                                Defaults to the latest version.

  -R,--root  <S3URI>            Deploy HPX from a custom s3 root location.
                                Set to the root of your custom HPX instance.
                                EXAMPLE: 's3://hpx-dev-us-west-2'

  -X,--execute                  If deploying to an existing stack, immediately
                                execute any changes. If not set, a changeset is
                                created for review before execution.

ENVIRONMENT VARIABLES:
  REDSHIFT_PASSWORD (required)  The Redshift master password to set.

  VPC_CIDR          (optional)  The IP block to use when creating VPC resources.
                                Example: '10.0.55/24' or 'fc00:100::/32'
                                Defaults to 172.16.0.0/16

  REDSHIFT_USER     (optional)  The Redshift root user to create.
                                Defaults to 'hpx'

  PREFIX            (optional)  The prefix to use when naming AWS resources.
                                Defaults to 'hpx'
EOF
}

main() {
  validate_environment_variables

  [ -z $(which aws) ] && err "AWS Cli not found!"
  REGION=$(aws configure get region)

  while [[ $# > 0 ]]; do
    case "$1" in
      -V|--version)
        HPX_VERSION=${2:-}
        [ -z $HPX_VERSION ] && err "(--version)_version string expected!"
        shift 2
        ;;
      -R|--root)
        HPX_ROOT=${2:-}
        [ -z $HPX_ROOT ] && err "(--custom) S3 location expected!"
        shift 2
        ;;
      -x|--execute)
        EXECUTE_CHANGESET="TRUE"
        shift
        ;;
      *)
        STACKNAME=$@
        shift $#
    esac
  done

  HPX_VERSION=${HPX_VERSION:-$(latest_version)}
  validate_version $HPX_VERSION

  validate_s3uri $HPX_ROOT/$HPX_VERSION
  DISTS3BUCKET=${HPX_ROOT:5}
  DISTS3KEY=$HPX_VERSION

  PREFIX=${PREFIX:-"hpx"}
  validate_prefix $PREFIX

  STACKNAME=${STACKNAME:-"$PREFIX-$REGION"}
  validate_stackname $STACKNAME

  REDSHIFT_USER=${REDSHIFT_USER:-"hpx"}
  validate_redshift_user $REDSHIFT_USER

  VPC_CIDR=${VPC_CIDR:-"172.31.0.0/16"}
  validate_ipv4_cidr $VPC_CIDR


  MYIP=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)
  WHITELIST_CIDR=${MYIP//\"/}/32
  #WHITELIST_CIDR=$(curl http://http://checkip.amazonaws.com/)/32
  validate_ipv4_cidr $WHITELIST_CIDR

  PARAMETERS=$(cat <<-EOF
  ParameterKey="WhitelistCidr",ParameterValue="$WHITELIST_CIDR"
  ParameterKey="Prefix",ParameterValue="$PREFIX"
  ParameterKey="DistS3Bucket",ParameterValue="$DISTS3BUCKET"
  ParameterKey="DistS3Key",ParameterValue="$DISTS3KEY"
  ParameterKey="RedshiftUser",ParameterValue="$REDSHIFT_USER"
  ParameterKey="RedshiftPassword",ParameterValue="$REDSHIFT_PASSWORD"
  ParameterKey="VpcCidrBlock",ParameterValue="$VPC_CIDR"
EOF
)
  if ! aws cloudformation describe-stacks --stack-name $STACKNAME > /dev/null 2>&1; then
    info "Creating new stack: $STACKNAME"
    aws cloudformation create-stack \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name "$STACKNAME" \
      --template-url "$(s3uri_to_s3url $HPX_ROOT/$HPX_VERSION/cloudformation/hpx.yaml)" \
      --parameters $PARAMETERS
  else
    info "Creating changeset for existing stack: $STACKNAME"
    aws cloudformation create-change-set \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name "$STACKNAME" \
      --template-url "$(s3uri_to_s3url $HPX_ROOT/$HPX_VERSION/cloudformation/hpx.yaml)" \
      --change-set-name "$PREFIX-changeset-$LUSER-$REGION" \
      --parameters $PARAMETERS

    if [ ${EXECUTE_CHANGESET:-FALSE} = TRUE ]; then
      aws cloudformation execute-change-set \
        --change-set-name "$PREFIX-changeset-$LUSER-$REGION"
    fi
  fi
}

latest_version() {
  aws s3 cp s3://$HPX_ROOT/LATEST - 2> /dev/null
}

validate_version() {
  [ -z ${1:-} ] && err "Missing version string!"
  [[ ! $1 =~ ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$ ]] && err "Version must match format ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$"
}

validate_stackname() {
  [ -z "$1" ] && err "Stack name must be set!"
  [[ ! "$1" =~ ^[a-zA-Z][-a-zA-Z0-9]{1,128}$ ]] && err "Invalid stack name ($1). Stackname must match ^[a-zA-Z][-a-zA-Z0-9]{1,128}$"
}

validate_s3uri() {
  [[ ! "$1" =~ ^s3://[a-zA-Z0-9.\-_]{1,255}/?.*$ ]] && err "Invalid S3URI ($1). S3URI must match ^s3://[a-zA-Z0-9.\-_]{1,255}/?.*$"
  ! aws s3 ls "$1" 2>&1 >/dev/null && err "Cannot access S3URI ($1)"
}

s3uri_to_s3url() {
  local awsregion=${REGION:-$(aws configure get region)}
  printf "https://s3-${awsregion}.amazonaws.com/${1:5}"
}

validate_prefix() {
  [[ ! "$1" =~ ^[a-zA-Z0-9]{1,16}$ ]] && err "Invalid prefix ($1). Prefix must match ^[a-zA-Z0-9]{1,16}$"
}

validate_redshift_user() {
  [ -z "$1" ] && err "Redshift user must be set!"
  [[ ! "$1" =~ ^[a-z]{1}[a-z0-9]{0,127}$ ]] && err "Invalid redshift user ($1). Redshift user must match ^[a-z]{1}[a-z0-9]{0,127}$"
}

validate_ipv4_cidr() {
  [[ ! "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$ ]] && \
  err "Invalid CIDR ($1)"
}

validate_environment_variables() {
  REQUIRED=(REDSHIFT_PASSWORD)
  for envvar in ${REQUIRED[@]}; do
    if [ -z "${!envvar:-}" ]; then
      err "Environment variable ${envvar} must be set!"
    fi
  done
}

info() {
  printf "[${SCRIPTNAME}] INFO: $1\n"
}

err() {
  printf "[${SCRIPTNAME}] ERROR: ${1:-Unknown Error!}\n"
  usage
  exit ${2:--1}
}

main "$@" || exit 1
