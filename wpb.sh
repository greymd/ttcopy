#!/bin/bash

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
LASTPASTE_PATH="${TMPDIR}/lastPaste"
ID_PREFIX="wpbcopy"

# Dependent services
CLIP_NET="https://cl1p.net"
TRANSFER_SH="https://transfer.sh"

spin_pid=""

spin::loop () {
    local message=$1
    tput civis # make the cursor invisible

    trap "exit;" SIGHUP SIGINT SIGQUIT SIGTERM
    yes "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏" | tr ' ' '\n' | while read spin;
    do
        echo -n "$spin $message \r" >&2
        sleep 1
    done
}

unspin() {
    kill $spin_pid
    wait $spin_pid

    tput cnorm # make the cursor visible
    echo -n "\r`tput el`" >&2
}

spin() {
    message=$1
    spin::loop $1 &
    spin_pid=$!
}

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
    # Start as the subshell so it can simply "exit" in trap, with unspinning.
    (
        is_env_ok || return -1
        spin "Copying..."

        # Don't forget to unspin when terminated by user, or it can be zombie
        trap "unspin; exit;" SIGHUP SIGINT SIGQUIT SIGTERM

        local TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWORD) $TRANSFER_SH/$WPB_ID );
        curl -s -X POST "$CLIP_NET/$ID_PREFIX/$WPB_ID" --data "content=$TRANS_URL" > /dev/null
        unspin
        echo "Copied!" >&2
    )
}

wpbpaste () {
    # Start as the subshell so it can simply "exit" in trap, with unspinning.
    (
        is_env_ok || return -1
        spin "Pasting..."

        # Don't forget to unspin when terminated by user, or it can be zombie
        trap "unspin; exit;" SIGHUP SIGINT SIGQUIT SIGTERM

        local TRANS_URL=$(curl -s "$CLIP_NET/$ID_PREFIX/$WPB_ID" | xmllint --html --xpath '/html/body/div/div/textarea/text()' - 2> /dev/null) || ""
        if [ "$TRANS_URL" = "" ]; then
            [ -f "$LASTPASTE_PATH" ] || return 1
            unspin
            echo "(Pasting the last paste)" >&2
            cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
            return 0
        fi
        local result=`curl -so- "$TRANS_URL" | tee "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD`;
        unspin
        echo $result
    )
}
