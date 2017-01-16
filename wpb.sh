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
MYID="your_id"
PASSWD="your_password"
LASTPASTE_PATH="${TMPDIR}/lastPaste"

wpbcopy () {
    local TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$PASSWD) https://transfer.sh/$MYID);
    curl -s -X POST "https://cl1p.net/$MYID" --data "content=$TRANS_URL" > /dev/null
}

wpbpaste () {
    local TRANS_URL=$(curl -s "https://cl1p.net/$MYID" | xmllint --html --xpath '/html/body/div/div/textarea/text()' -) 2> /dev/null || ""
    if [ "$TRANS_URL" = "" ]; then
        [ -f "$LASTPASTE_PATH" ] || return 1
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$PASSWD
        return 0
    fi
    curl -so- "$TRANS_URL" | tee "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$PASSWD
}
