#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
_TTCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

# Dependent commands (non POSIX commands)
_TTCP_DEPENDENCIES="${_TTCP_DEPENDENCIES:-yes openssl curl perl}"

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
TTCP_LASTPASTE_PATH="${TMPDIR}/lastPaste"
TTCP_ID_PREFIX="ttcopy"

# Dependent services
TTCP_CLIP_NET="${TTCP_CLIP_NET:-https://cl1p.net}"
TTCP_TRANSFER_SH="${TTCP_TRANSFER_SH:-https://transfer.sh}"

__ttcp::unspin () {
    kill $_TTCP_SPIN_PID
    tput cnorm >&2 # make the cursor visible
    echo -n $'\r'"`tput el`" >&2
}

__ttcp::spin () {
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

    _TTCP_SPIN_PID=$!
}

__ttcp::is_env_ok () {
    while read cmd ; do
        type $cmd > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "$cmd is required to work." >&2
            # `return -1` does not work in particular situation. `-1` is recognized as an option.
            # After `--`, any arguments are not interpreted as option.
            return -- -1
        fi
    done < <(echo "$_TTCP_DEPENDENCIES" | tr ' ' '\n')

    [ -z "$TTCP_ID" ] && echo "Set environment variable (TTCP_ID)." >&2 && return -- -1
    [ -z "$TTCP_PASSWORD" ] && echo "Set environment variable (TTCP_PASSWORD)." >&2 && return -- -1
    return 0
}

ttcopy () {
    TTCP_ID="$TTCP_ID" TTCP_PASSWORD="$TTCP_PASSWORD" "$_TTCP_DIR"/ttcopy.sh
}

ttpaste () {
    TTCP_ID="$TTCP_ID" TTCP_PASSWORD="$TTCP_PASSWORD" "$_TTCP_DIR"/ttpaste.sh
}
