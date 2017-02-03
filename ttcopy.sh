#!/bin/bash

# Portable and reliable way to get the directory of this script.
# Based on http://stackoverflow.com/a/246128
# then added zsh support from http://stackoverflow.com/a/23259585 .
_TTCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"
source "$_TTCP_DIR"/ttcp.sh

# Option parser is called prior to is_env_ok
# Because id/password might be given by user.
__ttcp::opts "$@"
_opt_status=$?

# There is invalid options/arguments.
if [ $_opt_status -eq 4 ]; then
    exit $_TTCP_EINVAL

# Shows usage or version number.
elif [ $_opt_status -eq 254 ]; then
    exit 0
fi

__ttcp::is_env_ok

trap "__ttcp::unspin; kill 0; exit $_TTCP_EINTR" SIGHUP SIGINT SIGQUIT SIGTERM
__ttcp::spin "Copying..."

TRANS_URL=$(curl -so- --fail --upload-file <(cat | openssl aes-256-cbc -e -pass pass:$TTCP_PASSWORD) $TTCP_TRANSFER_SH/$TTCP_ID );

if [ $? -ne 0 ]; then
    __ttcp::unspin
    echo "Failed to upload the content" >&2
    exit $_TTCP_ECONTTRANS
fi

curl -s -X POST "$TTCP_CLIP_NET/$TTCP_ID_PREFIX/$TTCP_ID" --fail --data "content=$TRANS_URL" > /dev/null

if [ $? -ne 0 ]; then
    __ttcp::unspin
    echo "Failed to save the content url" >&2
    exit $_TTCP_ECONTURL
fi

__ttcp::unspin
echo "Copied!" >&2
exit 0
