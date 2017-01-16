# Usage
# $ echo ほげほげ | wpbcopy
# $ wpbpaste
# ほげほげ

MYSTR="myclip"
LASTPASTE_PATH="${TMPDIR}/lastPaste"
wpbcopy () {
    local TRANS_URL=$(curl -so- --upload-file <(cat) https://transfer.sh/$MYSTR);
    curl -s -X POST "https://cl1p.net/$MYSTR" --data "content=$TRANS_URL" > /dev/null
}

wpbpaste () {
    local TRANS_URL=$(curl -s "https://cl1p.net/$MYSTR" | xmllint --html --xpath '/html/body/div/div/textarea/text()' -) 2> /dev/null || ""
    if [ "$TRANS_URL" = "" ]; then
        [ -f $LASTPASTE_PATH ] || return 1
        echo "(Pasting the last paste)" >&2
        cat "$LASTPASTE_PATH"
        return 0
    fi
    curl -so- "$TRANS_URL" | tee "$LASTPASTE_PATH"
}

