#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
_TTCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

source "$_TTCP_DIR"/ttcp.sh

__ttcp::is_env_ok || exit -1

trap "__ttcp::unspin; kill 0; exit 2" SIGHUP SIGINT SIGQUIT SIGTERM
__ttcp::opts "$@"
__ttcp::spin "Pasting..."

TTCP_LASTPASTE_PATH="${TTCP_LASTPASTE_PATH_PREFIX}${TTCP_ID}"
CLIP_BODY=$(curl --fail -so- "$TTCP_CLIP_NET/$TTCP_ID_PREFIX/$TTCP_ID" 2> /dev/null)
if [ $? -ne 0 ]; then
    __ttcp::unspin
    echo "Failed to get the content url" >&2
    exit 129
fi

TRANS_URL=$(echo "$CLIP_BODY" |
                   # Use only (extended) regular expression compatible with POSIX.
                   sed 's/<[^>]*>//g' | grep -E "${TTCP_TRANSFER_SH}/[^/]+/.+" | head -n 1 2> /dev/null)


if [ "$TRANS_URL" = "" ]; then
    [ -f "$TTCP_LASTPASTE_PATH" ] ||
        { __ttcp::unspin;
          echo "Nothing has been copied yet." >&2;
          exit 1; }

    __ttcp::unspin
    echo "(Pasting the last paste)" >&2
    cat "$TTCP_LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$TTCP_PASSWORD
    exit 0
fi
curl --fail -so- "$TRANS_URL" > "$TTCP_LASTPASTE_PATH" 2> /dev/null
if [ $? -ne 0 ]; then
    __ttcp::unspin
    echo "Failed to get the content" >&2
    exit 128
fi

__ttcp::unspin
cat "$TTCP_LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$TTCP_PASSWORD
exit 0

