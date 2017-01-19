#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
WPB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

source "$WPB_DIR"/wpb.sh

(
    is_env_ok || exit -1

    # Use only (extended) regular expression compatible with POSIX.
    TRANS_URL=$(curl -s "$CLIP_NET/$ID_PREFIX/$WPB_ID" | sed 's/<[^>]*>//g' | grep -E "${TRANSFER_SH}/[^/]+/.+" | head -n 1 2> /dev/null) || $(echo "")
    if [ "$TRANS_URL" = "" ]; then
        [ -f "$LASTPASTE_PATH" ] || exit 1
        unspin
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
        exit 0
    fi
    curl -so- "$TRANS_URL" > "$LASTPASTE_PATH"
    unspin
    cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
) &

trap "kill 0; exit" SIGHUP SIGINT SIGQUIT SIGTERM
spin $! "Pasting..."
