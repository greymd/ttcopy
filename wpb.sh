#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
WPB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

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
        type $cmd > /dev/null
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
    WPB_ID="$WPB_ID" WPB_PASSWORD="$WPB_PASSWORD" "$WPB_DIR"/wpbcopy.sh
}

wpbpaste () {
    WPB_ID="$WPB_ID" WPB_PASSWORD="$WPB_PASSWORD" "$WPB_DIR"/wpbpaste.sh
}
