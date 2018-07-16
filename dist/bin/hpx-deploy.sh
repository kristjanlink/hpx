#!/bin/bash
set -u

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
LUSER=$(whoami)
HPX_ROOT="${HPX_ROOT:-"s3://hpx-release-us-west-2"}"

usage() {
    cat 1>&2 <<EOF
$SCRIPTNAME

USAGE:
  hpx-deploy [OPTIONS]

OPTIONS:
  -S,--stack                    Name of the stack you wish to create or update.
                                Defaults to 'hpx-<AWS REGION>', or if PREFIX is
                                set, '<PREFIX>-<AWS REGION>'

  -V,--version <version>        Select the version of HPX to deploy.
                                Defaults to the latest version.

  -R,--root  <S3URI>            Deploy HPX from a custom s3 root location.
                                Set to the root of your custom HPX instance.
                                EXAMPLE: 's3://hpx-dev-us-west-2'

  -X,--execute                  If deploying to an existing stack, immediately
                                execute any changes. If not set, a changeset is
                                created for review before execution.

  -C,--config                   Use or create the specified configuration file.
                                Defaults to '~/.hpx/default' if not set.

  -D,--dryrun                   Does not deploy HPX, but prints the
                                aws commands that will be called.

  --status                      Check the status of a stack being created or
                                updated.

  -h,--help                     Print this message

ENVIRONMENT/CONFIG VARIABLES:
  HPX_CFG                       Environment file to use unless --config
                                is specified. Defaults to '~/.hpx/default'

  HPX_ROOT                      S3 root location to deploy HPX from
                                unless --root is specified.
                                Defaults to 's3://hpx-release-us-west-2'

  HPX_VERSION                   HPX version to deploy unless --version
                                is specified. Defaults to LATEST.

  REDSHIFT_PASSWORD             Redshift master password to set. If not set,
                                a new, random password will be created.

  VPC_CIDR                      IP block to use when creating VPC resources.
                                Example: '10.0.55/24' or 'fc00:100::/32'
                                Defaults to '172.16.0.0/16'

  REDSHIFT_USER                 Redshift root user to create.
                                Defaults to 'hpx'

  PREFIX                        Prefix to use when creating AWS resources.
                                Defaults to 'hpx'. Setting different PREFIX
                                enables deployment of multiple HPX stacks within
                                the same AWS account.
                                (Note: AWS limits the number of certain
                                resources that can be deployed. See the AWS
                                Trusted Advisor console for details)

FILES:
  ~/.hpx/default                Configuration file used by HPX (unless
                                specified through HPX_CFG or --config). Use
                                this file to add environment variables.
                                After initial configuration, this file will
                                contain the REDSHIFT_PASSWORD.
EOF
exit
}

main() {
  [ "${1:-}" = "help" ] && usage

  [ -z "$(which aws)" ] && err "AWS Cli not found!"
  REGION=$(aws configure get region)

  SUBCOMMAND="deploy"

  while [[ $# > 0 ]]; do
    case "$1" in
      -S|--stack)
        STACKNAME="${2:-}"
        [ -z "$STACKNAME" ] && err "(--stack) Stack name expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -V|--version)
        HPX_VERSION="${2:-}"
        [ -z "$HPX_VERSION" ] && err "(--version) Version string expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -R|--root)
        HPX_ROOT="${2:-}"
        [ -z "$HPX_ROOT" ] && err "(--root) S3 location expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -X|--execute)
        EXECUTE_CHANGESET="TRUE"
        HPX_OPTIONS+=("$1")
        shift
        ;;
      -C|--config)
        HPX_CFG="${2:-}"
        [ -z "$HPX_CFG" ] && err "(--config) Filename expected!"
        HPX_OPTIONS+=("$1" "$2")
        shift 2
        ;;
      -D|--dryrun)
        DRYRUN="| "
        HPX_OPTIONS+=("$1")
        shift
        ;;
      --status)
        SUBCOMMAND="status"
        shift
        ;;
      -h|--help)
        usage
        ;;
      *)
        HPX_OPTIONS+=("$1")
        shift
    esac
  done

  HPX_CFG="${HPX_CFG:-"$HOME/.hpx/default"}"
  validate_hpx_cfg "$HPX_CFG"
  source "$HPX_CFG"

  PREFIX="${PREFIX:-"hpx"}"
  validate_prefix "$PREFIX"

  STACKNAME="${STACKNAME:-"$PREFIX-$REGION"}"
  validate_stackname "$STACKNAME"

  case "$SUBCOMMAND" in
    deploy)
      deploy
      ;;
    status)
      status
      ;;
    *)
      usage
  esac
}

deploy() {
  HPX_VERSION="${HPX_VERSION:-"$(latest_version)"}"
  validate_version "$HPX_VERSION"

  validate_s3uri "$HPX_ROOT/$HPX_VERSION"
  DISTS3BUCKET="${HPX_ROOT:5}"
  DISTS3KEY="$HPX_VERSION"

  REDSHIFT_USER="${REDSHIFT_USER:-"hpx"}"
  validate_redshift_user "$REDSHIFT_USER"

  if [ -z "${REDSHIFT_PASSWORD:-}" ]; then
    REDSHIFT_PASSWORD="$( create_redshift_password )"
    printf "REDSHIFT_PASSWORD=\"$REDSHIFT_PASSWORD\"\n" >> "$HPX_CFG"
  else
    validate_redshift_password "$REDSHIFT_PASSWORD"
  fi

  VPC_CIDR="${VPC_CIDR:-"172.31.0.0/16"}"
  validate_ipv4_cidr "$VPC_CIDR"

  WHITELIST_CIDR="$(my_ip)/32"
  validate_ipv4_cidr "$WHITELIST_CIDR"

  write_defaults

  PARAMETERS=(
  ParameterKey="Prefix",ParameterValue="$PREFIX"
  ParameterKey="DistS3Bucket",ParameterValue="$DISTS3BUCKET"
  ParameterKey="DistS3Key",ParameterValue="$DISTS3KEY"
  ParameterKey="RedshiftUser",ParameterValue=\""$REDSHIFT_USER"\"
  ParameterKey="RedshiftPassword",ParameterValue=\""$REDSHIFT_PASSWORD"\"
  ParameterKey="VpcCidrBlock",ParameterValue="$VPC_CIDR"
  ParameterKey="WhitelistCidr",ParameterValue="$WHITELIST_CIDR"
  )

  if ! aws cloudformation describe-stacks --stack-name "$STACKNAME" > /dev/null 2>&1; then
    info "Creating new stack: $STACKNAME"
    dryrun aws cloudformation create-stack \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name "$STACKNAME" \
      --template-url "$(s3uri_to_s3url $HPX_ROOT/$HPX_VERSION/cloudformation/hpx.yaml)" \
      --parameters "${PARAMETERS[@]}"

    info "Stack creation may take 20 minutes or longer. \
    Run \"$SCRIPTNAME --status\" to check on the status of your stack, "
  else
    info "Creating changeset for existing stack: $STACKNAME"
    CHANGESET="$PREFIX-changeset-$LUSER-$REGION"
    dryrun aws cloudformation create-change-set \
      --capabilities CAPABILITY_NAMED_IAM \
      --stack-name "$STACKNAME" \
      --template-url "$(s3uri_to_s3url $HPX_ROOT/$HPX_VERSION/cloudformation/hpx.yaml)" \
      --change-set-name "$CHANGESET" \
      --parameters "${PARAMETERS[@]}"

    if [ ${EXECUTE_CHANGESET:-"FALSE"} = "TRUE" ]; then
      info "Waiting for changeset to finish creating: $CHANGESET"
      dryrun aws cloudformation wait change-set-create-complete \
        --change-set-name "$CHANGESET" \
        --stack-name "$STACKNAME"

      info "Executing changeset: $CHANGESET"
      dryrun aws cloudformation execute-change-set \
        --change-set-name "$CHANGESET" \
        --stack-name "$STACKNAME"
    fi
  fi
}

status() {
  local status="$(aws cloudformation describe-stacks --stack-name $STACKNAME --output text  | awk 'FNR == 1 {print $7;}')"

  case "$status" in
    CREATE_COMPLETE|UPDATE_COMPLETE)
      info "Stack create/update succeded!"
      local redshift_cluster="$(aws cloudformation describe-stack-resources --stack-name $STACKNAME --output text  | awk '{if ($2 == "HPXRedshiftCluster") print $3;}')"
      local REDSHIFT_ENDPOINT="$(aws redshift describe-clusters --cluster-identifier $redshift_cluster --output text | awk '{if ($1 == "ENDPOINT") print $2 ":" $3;}')"
      info "*** Your redshift endpoint is $REDSHIFT_ENDPOINT"
      info "*** Connect to redshift with user \'$REDSHIFT_USER\' and password \'$REDSHIFT_PASSWORD\'."
      info "*** You can find also find your Redshift user and password in \'$HPX_CFG\'"

      local cloudfront_id="$(aws cloudformation describe-stack-resources --stack-name $STACKNAME --output text  | awk '{if ($2 == "PixelServerCloudfrontDistribution") print $3;}')"
      local cloudfront_host="$(aws cloudfront get-distribution --id $cloudfront_id --output text | awk '{if ($1 == "DISTRIBUTION") print $3}')"
      info "*** Your pixel url is http://$cloudfront_host/1x1.gif?a=value1&b=value2&c=value3&value4"
      ;;
    CREATE_IN_PROGRESS|UPDATE_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS)
      info "Stack creation/update still in progress."
      ;;
    REVIEW_IN_PROGRESS)
      info "Stack creation/update is being reviewed."
      ;;
    *)
      NOUSAGE=TRUE err "Stack create/update failed! Check the AWS cloudformation console for details ($STACKNAME)"
  esac
}

my_ip() {
  local ip
  if [ -n "$(which dig)" ]; then
    ip="$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)"
  elif [ -n "$(which curl)" ]; then
    ip="$(curl -s http://checkip.amazonaws.com/)"
  elif [ -n "$(which wget)" ]; then
    ip="$(wget -qO- http://checkip.amazonaws.com/)"
  else
    err "Can't get user's ip address!"
  fi
  printf ${ip//\"/}
}

is_valid_redshift_password() {
  [[ (("$1" =~ ^.{8,64}$) && ( "$1" =~ [A-Z]+ ) && ( "$1" =~ [a-z]+ ) && ( "$1" =~ [0-9]+ )) ]]
}

validate_redshift_password() {
  ! is_valid_redshift_password "$1" && err 'Redshift Password invalid!
  - Password must It must be 8 to 64 characters in length.
  - Must contain at least one uppercase letter, one lowercase letter, and one number.
  - Cannot contain '\'' (single quote), " (double quote), :, \, /, @, or space.'
}

create_redshift_password() {
  local rpw=""
  while ! is_valid_redshift_password "$rpw"; do
    rpw="$( LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 13 )"
  done
  printf "$rpw"
}

latest_version() {
  local latest="$(aws s3 cp "$HPX_ROOT/LATEST" - 2> /dev/null)"
  [ -z latest ] && err "Could not find latest version! Check your internet connection."
  printf "$latest"
}

validate_hpx_cfg() {
  mkdir -p "$(dirname "$1")"
  touch "$1"
  [ ! -r "$1" -a -w "$1" ] && err "Cannot access environment file ($1)!"
}

validate_version() {
  [ -z "${1:-}" ] && err "Missing version string!"
  [[ ! "$1" =~ ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$ ]] && err "Version ($HPX_VERSION) must match format ^[0-9]+\.[0-9]+(\.[0-9]+[a-zA-Z]*){0,1}$"
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
  local awsregion="${REGION:-$(aws configure get region)}"
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

write_defaults() {
  for envvar in PREFIX HPX_ROOT REDSHIFT_USER REDSHIFT_PASSWORD VPC_CIDR WHITELIST_CIDR; do
    if [ -z "$(grep "^$envvar=" "$HPX_CFG")" ]; then
      printf "\n$envvar=\"${!envvar}\"" >> "$HPX_CFG"
    fi
  done
}

info() {
  printf "[${SCRIPTNAME}] INFO: $1\n"
}

err() {
  printf "[${SCRIPTNAME}] ERROR: %s\n" "${1:-Unknown Error!}"
  [ -z ${NOUSAGE:-} ] && usage
  exit -1
}

dryrun() {
  if [ -n "${DRYRUN:-}" ]; then
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
