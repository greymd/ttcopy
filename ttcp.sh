#!/bin/bash

# Version number of commands.
# MAJOR.MINOR.PATCH
readonly TTCP_VERSION="1.1.0"

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
_TTCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

# Dependent commands (non POSIX commands)
_TTCP_DEPENDENCIES="${_TTCP_DEPENDENCIES:-yes openssl curl perl}"

# Whare the last pasted content stored is.
# It is re-used when you failed to get the remote content.
TTCP_LASTPASTE_PATH_PREFIX="${TMPDIR}/lastPaste_"
TTCP_ID_PREFIX="ttcopy"

# Dependent services
TTCP_CLIP_NET="${TTCP_CLIP_NET:-https://cl1p.net}"
TTCP_TRANSFER_SH="${TTCP_TRANSFER_SH:-https://transfer.sh}"

__ttcp::version () {
    echo "${TTCP_VERSION}"
}

__ttcp::usage () {
    # Get a filename calling the function.
    # http://stackoverflow.com/a/192319/
    local _file="${0##*/}"
    # Remove file's extention
    local _cmd="${_file%.*}"

    echo "  Usage: $_cmd [OPTIONS]"
    echo
    echo "  OPTIONS:"
    echo "  -h, --help                         Output a usage message and exit."
    echo "  -V, --version                      Output the version number of $_cmd and exit."
    echo "  -i ID, --id=ID                     Specify ID to identify the data."
    echo "  -p PASSWORD, --password=PASSWORD   Specify password to encrypt/decrypt the data."
}

__ttcp::opts () {
    # This way supports options which consist continuous letters (like `-Vh`).
    # http://qiita.com/b4b4r07/items/dcd6be0bb9c9185475bb
    while (( $# > 0 ))
    do
        case "$1" in

            # Long options
            --help)
                __ttcp::usage
                return 254
                ;;
            --version)
                __ttcp::version
                return 254
                ;;
            --id=*)
                TTCP_ID="${1#--id=}"
                shift
                ;;
            --password=*)
                TTCP_PASSWORD="${1#--password=}"
                shift
                ;;

            # Short options
            -[hVip])
                # For --help
                if [[ "$1" =~ 'h' ]]; then
                    __ttcp::usage
                    return 254
                fi

                # For --version
                if [[ "$1" =~ 'V' ]]; then
                    __ttcp::version
                    return 254
                fi

                # For --id
                if [[ "$1" =~ 'i' ]]; then
                    TTCP_ID="$2"
                    shift

                # For --password
                elif [[ "$1" =~ 'p' ]]; then
                    TTCP_PASSWORD="$2"
                    shift
                fi

                # Rotate arguments
                shift
                ;;

            # Other options
            -*)
                # Same error message as `grep` command.
                echo "Invalid option -- '${1#-}'" >&2
                __ttcp::usage
                return 4
                ;;

            # Other
            *)
                # Show usage and exit
                echo "Invalid argument -- '${1}'" >&2
                __ttcp::usage
                return 4
                ;;

        esac
    done
    return 0
}

__ttcp::unspin () {
    kill $_TTCP_SPIN_PID 2> /dev/null
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

    [ -z "$TTCP_ID" ] && echo "Set environment variable (TTCP_ID) or give the ID by -i option." >&2 && return -- -1
    [ -z "$TTCP_PASSWORD" ] && echo "Set environment variable (TTCP_PASSWORD) or give the password by -p option." >&2 && return -- -1
    return 0
}

ttcopy () {
    TTCP_ID="$TTCP_ID" TTCP_PASSWORD="$TTCP_PASSWORD" "$_TTCP_DIR"/ttcopy.sh "$@"
}

ttpaste () {
    TTCP_ID="$TTCP_ID" TTCP_PASSWORD="$TTCP_PASSWORD" "$_TTCP_DIR"/ttpaste.sh "$@"
}
