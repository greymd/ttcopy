#!/bin/bash

[ -z "$WPB_ID" ] && echo "Set environment variable (WPB_ID)." >&2 && exit 1
[ -z "$WPB_PASSWORD" ] && (echo "Set environment variable (WPB_PASSWORD)." >&2 && exit 1

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
LASTPASTE_PATH="${TMPDIR}/lastPaste"

wpbcopy () {
    local TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWORD) https://transfer.sh/$WPB_ID);
    curl -s -X POST "https://cl1p.net/$WPB_ID" --data "content=$TRANS_URL" > /dev/null
}

wpbpaste () {
    local TRANS_URL=$(curl -s "https://cl1p.net/$WPB_ID" | xmllint --html --xpath '/html/body/div/div/textarea/text()' -) 2> /dev/null || ""
    if [ "$TRANS_URL" = "" ]; then
        [ -f "$LASTPASTE_PATH" ] || return 1
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
        return 0
    fi
    curl -so- "$TRANS_URL" | tee "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
}
