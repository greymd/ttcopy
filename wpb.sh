# Usage

## Example 1 (Text)
# $ echo foobar | wpbcopy
# $ wpbpaste
# foobar

## Example 2 (Binary)
# $ cat image.jpg| wpbcopy
# $ wpbpaste | file -
# /dev/stdin: JPEG image data, JFIF standard 1.01

MYSTR="myclip"
wpbcopy () {
    local TRANS_URL=$(curl -so- --upload-file <(cat) https://transfer.sh/$MYSTR);
    curl -s -X POST "https://cl1p.net/$MYSTR" --data "content=$TRANS_URL" > /dev/null
}

wpbpaste () {
    local TRANS_URL=$(curl -s "https://cl1p.net/$MYSTR" | xmllint --html --xpath '/html/body/div/div/textarea/text()' -)
    curl -so- "$TRANS_URL"
}