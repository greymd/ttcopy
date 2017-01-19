#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
WPB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

source "$WPB_DIR"/wpb.sh
is_env_ok || exit -1

makePipe

cat - | (
    TRANS_URL=$(curl -so- --fail --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWORD) $TRANSFER_SH/$WPB_ID );

    if [ $? -ne 0 ]; then
        unspin
        echo "Failed to upload the content" >&2
        exit_ 128
    fi

    curl -s -X POST "$CLIP_NET/$ID_PREFIX/$WPB_ID" --fail --data "content=$TRANS_URL" > /dev/null

    if [ $? -ne 0 ]; then
        unspin
        echo "Failed to save the content url" >&2
        exit_ 129
    fi

    unspin
    echo "Copied!" >&2
    exit_ 0
) &

trap "kill 0; exit 2" SIGHUP SIGINT SIGQUIT SIGTERM
spin $! "Copying..."

exit $(waitExitcode)
