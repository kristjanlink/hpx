#!/bin/bash
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$SCRIPTDIR/dist.sh
$SCRIPTDIR/create-changeset.sh
