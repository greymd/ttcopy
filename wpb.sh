# Usage
# $ echo ほげほげ | wpbcopy
# $ wpbpaste
# ほげほげ

wpbcopy () {
    local TRANS_URL=$(curl -so- --upload-file <(cat) https://transfer.sh/myclip);
    curl -s -X POST 'https://cl1p.net/myclip' --data "content=$TRANS_URL" -w "%{http_code}" > /dev/null
}

wpbpaste () {
    local TRANS_URL=$(curl -s 'https://cl1p.net/myclip' | xmllint --html --xpath '/html/body/div/div/textarea/text()' -)
    curl -so- "$TRANS_URL"
}