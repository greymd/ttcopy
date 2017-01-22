#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
_WPB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

source "$_WPB_DIR"/wpb.sh

__wpb::is_env_ok || exit -1

trap "kill 0; exit 2" SIGHUP SIGINT SIGQUIT SIGTERM
__wpb::spin "Pasting..."

CLIP_BODY=$(curl --fail -so- "$WPB_CLIP_NET/$WPB_ID_PREFIX/$WPB_ID" 2> /dev/null)
if [ $? -ne 0 ]; then
    __wpb::unspin
    echo "Failed to get the content url" >&2
    exit 129
fi

TRANS_URL=$(echo "$CLIP_BODY" |
                   # Use only (extended) regular expression compatible with POSIX.
                   sed 's/<[^>]*>//g' | grep -E "${WPB_TRANSFER_SH}/[^/]+/.+" | head -n 1 2> /dev/null)

if [ "$TRANS_URL" = "" ]; then
    [ -f "$WPB_LASTPASTE_PATH" ] ||
        { __wpb::unspin;
          echo "Nothing has been copied yet." >&2;
          exit 1; }

    __wpb::unspin
    echo "(Pasting the last paste)" >&2
    cat "$WPB_LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
    exit 0
fi
curl --fail -so- "$TRANS_URL" > "$WPB_LASTPASTE_PATH" 2> /dev/null
if [ $? -ne 0 ]; then
    __wpb::unspin
    echo "Failed to get the content" >&2
    exit 128
fi

__wpb::unspin
cat "$WPB_LASTPASTE_PATH" | openssl aes-256-cbc -d -pass pass:$WPB_PASSWORD
exit 0

