#!/bin/bash

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
LASTPASTE_PATH="${TMPDIR}/lastPaste"
ID_PREFIX="wpbcopy"

# Dependent services
CLIP_NET="https://cl1p.net"
TRANSFER_SH="https://transfer.sh"

unspin () {
    tput cnorm >&2 # make the cursor visible
    echo -n $'\r'"`tput el`" >&2
}

spin () {
    local pid=$1
    local message=$2
    tput civis >&2 # make the cursor invisible

    yes "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏" | tr ' ' '\n' | while read spin;
    do
        kill -0 $pid 2> /dev/null
        if [ $? -ne 0 ]; then
            exit;
        fi

        echo -n "$spin $message "$'\r' >&2
        perl -e 'select(undef, undef, undef, 0.25)' # sleep 0.25s
    done
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
    cat - | (
        is_env_ok || return -1

        trap "kill 0; exit" SIGHUP SIGINT SIGQUIT SIGTERM

        local TRANS_URL=$(curl -so- --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$WPB_PASSWORD) $TRANSFER_SH/$WPB_ID );
        curl -s -X POST "$CLIP_NET/$ID_PREFIX/$WPB_ID" --data "content=$TRANS_URL" > /dev/null
        unspin
        echo "Copied!" >&2
    ) &

    (
        # Start as the subshell so it can simply "exit" in trap,
        # with killing background process.

        trap "kill $!; exit" SIGHUP SIGINT SIGQUIT SIGTERM
        spin $! "Copying..."
    )
}

wpbpaste () {
    (
        is_env_ok || return -1

        trap "kill 0; exit" SIGHUP SIGINT SIGQUIT SIGTERM

        local TRANS_URL=$(curl -s "$CLIP_NET/$ID_PREFIX/$WPB_ID" | xmllint --html --xpath '/html/body/div/div/textarea/text()' - 2> /dev/null) || ""
        if [ "$TRANS_URL" = "" ]; then
            [ -f "$LASTPASTE_PATH" ] || return 1
            echo "(Pasting the last paste)" >&2
            unspin
            cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
            return 0
        fi
        curl -so- "$TRANS_URL" > "$LASTPASTE_PATH"
        unspin
        cat "$LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
    ) &

    (
        # Start as the subshell so it can simply "exit" in trap,
        # with killing background process.

        trap "kill $!; exit" SIGHUP SIGINT SIGQUIT SIGTERM
        spin $! "Pasting..."
    )
}
