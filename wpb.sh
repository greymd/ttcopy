#!/bin/bash

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
LASTPASTE_PATH="${TMPDIR}/lastPaste"
ID_PREFIX="wpbcopy"

# Dependent services
CLIP_NET="https://cl1p.net"
TRANSFER_SH="https://transfer.sh"

is_env_ok () {
    echo "openssl curl xmllint" | xargs -n 1 | while read cmd ; do
        which $cmd > /dev/null
        if [ $? -ne 0 ]; then
            echo "$cmd is required to work."
            return -1
        fi
    done
    [ -z "$WPB_ID" ] && echo "Set environment variable (WPB_ID)." >&2 && return -1
    [ -z "$WPB_PASSWORD" ] && echo "Set environment variable (WPB_PASSWORD)." >&2 && return -1
    return 0
}

wpbcopy () {
    is_env_ok || return -1
    local TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWORD) $TRANSFER_SH/$WPB_ID );
    curl -s -X POST "$CLIP_NET/$ID_PREFIX/$WPB_ID" --data "content=$TRANS_URL" > /dev/null
}

wpbpaste () {
    is_env_ok || return -1
    local TRANS_URL=$(curl -s "$CLIP_NET/$ID_PREFIX/$WPB_ID" | xmllint --html --xpath '/html/body/div/div/textarea/text()' - 2> /dev/null) || ""
    if [ "$TRANS_URL" = "" ]; then
        [ -f "$LASTPASTE_PATH" ] || return 1
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
        return 0
    fi
    curl -so- "$TRANS_URL" | tee "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
}
