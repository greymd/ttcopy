#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
WPB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

source "$WPB_DIR"/wpb.sh

is_env_ok || exit -1

makePipe

(
    CLIP_BODY=$(curl --fail -so- "$CLIP_NET/$ID_PREFIX/$WPB_ID" 2> /dev/null)
    if [ $? -ne 0 ]; then
        unspin
        echo "Failed to get the content url" >&2
        exit_ 129
    fi

    TRANS_URL=$(echo "$CLIP_BODY" |
                        # Use only (extended) regular expression compatible with POSIX.
                       sed 's/<[^>]*>//g' | grep -E "${TRANSFER_SH}/[^/]+/.+" | head -n 1 2> /dev/null)

    if [ "$TRANS_URL" = "" ]; then
        [ -f "$LASTPASTE_PATH" ] ||
            { unspin;
              echo "Nothing has been copied yet.";
              exit_ 1; }

        unspin
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
        exit_ 0
    fi
    curl --fail -so- "$TRANS_URL" > "$LASTPASTE_PATH" 2> /dev/null
    if [ $? -ne 0 ]; then
        unspin
        echo "Failed to get the content" >&2
        exit_ 128
    fi

    unspin
    cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
    exit_ 0
) &

trap "kill 0; exit 2" SIGHUP SIGINT SIGQUIT SIGTERM
spin $! "Pasting..."

exit $(waitExitcode)
