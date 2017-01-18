#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
WPB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

source "$WPB_DIR"/wpb.sh

cat - | (
    is_env_ok || exit -1
    
    TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWORD) $TRANSFER_SH/$WPB_ID );
    curl -s -X POST "$CLIP_NET/$ID_PREFIX/$WPB_ID" --data "content=$TRANS_URL" > /dev/null
    unspin
    echo "Copied!" >&2
) &

trap "kill 0; exit" SIGHUP SIGINT SIGQUIT SIGTERM
spin $! "Copying..."

