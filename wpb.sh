# Usage

## Example 1 (Text)
# $ echo foobar | wpbcopy
# $ wpbpaste
# foobar

## Example 2 (Binary)
# $ cat image.jpg| wpbcopy
# $ wpbpaste | file -
# /dev/stdin: JPEG image data, JFIF standard 1.01

# Set ID and PASSWORD **AS YOU LIKE**.
WPB_ID="your_id"
WPB_PASSWARD="your_password"

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
LASTPASTE_PATH="${TMPDIR}/lastPaste"

wpbcopy () {
    local TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWARD) https://transfer.sh/$WPB_ID);
    curl -s -X POST "https://cl1p.net/$WPB_ID" --data "content=$TRANS_URL" > /dev/null
}

wpbpaste () {
    local TRANS_URL=$(curl -s "https://cl1p.net/$WPB_ID" | xmllint --html --xpath '/html/body/div/div/textarea/text()' -) 2> /dev/null || ""
    if [ "$TRANS_URL" = "" ]; then
        [ -f "$LASTPASTE_PATH" ] || return 1
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWARD
        return 0
    fi
    curl -so- "$TRANS_URL" | tee "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWARD
}
