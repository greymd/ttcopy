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
CLIP_NET="${CLIP_NET:-https://cl1p.net}"
TRANSFER_SH="${TRANSFER_SH:-https://transfer.sh}"

# Dependent commands (non POSIX commands)
DEPENDENCIES="${DEPENDENCIES:-yes openssl curl perl}"

unspin () {
    kill $SPIN_PID
    tput cnorm >&2 # make the cursor visible
    echo -n $'\r'"`tput el`" >&2
}

spin () {
    local message=$1
    tput civis >&2 # make the cursor invisible

    (
        # Use process substitution instead of the pipe
        # (i.e. `yes "..." | tr ' ' '\n' | while read spin;`)
        # to give the `spin`, in order to avoid creating sub-shell.
        # It could cause the loops be zombie and unable to break it.

        while read spin;
        do
            echo -n "$spin $message "$'\r' >&2
            perl -e 'select(undef, undef, undef, 0.25)' # sleep 0.25s
        done < <(yes "⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏" | tr ' ' '\n')
    )&

    SPIN_PID=$!
}

is_env_ok () {
    while read cmd ; do
        type $cmd > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "$cmd is required to work." >&2
            # `return -1` does not work in particular situation. `-1` is recognized as an option.
            # After `--`, any arguments are not interpreted as option.
            return -- -1
        fi
    done < <(echo "$DEPENDENCIES" | tr ' ' '\n')

    [ -z "$WPB_ID" ] && echo "Set environment variable (WPB_ID)." >&2 && return -- -1
    [ -z "$WPB_PASSWORD" ] && echo "Set environment variable (WPB_PASSWORD)." >&2 && return -- -1
    return 0
}

wpbcopy () {
    WPB_ID="$WPB_ID" WPB_PASSWORD="$WPB_PASSWORD" "$WPB_DIR"/wpbcopy.sh
}

wpbpaste () {
    WPB_ID="$WPB_ID" WPB_PASSWORD="$WPB_PASSWORD" "$WPB_DIR"/wpbpaste.sh
}
