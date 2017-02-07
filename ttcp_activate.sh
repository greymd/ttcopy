#!/bin/bash

# If ttcopy or ttpaste is not executable, add the entry into PATH.
if ! (type ttcopy > /dev/null 2>&1 &&
       type ttpaste > /dev/null 2>&1); then

    # Portable and reliable way to get the directory of tha parent of this script.
    # Based on http://stackoverflow.com/a/246128
    # then added zsh support from http://stackoverflow.com/a/23259585 .
    _TTCP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

    export PATH="$PATH:$_TTCP_DIR/bin"
fi

# Otherwise, add ttcopy's /bin to $PATH.

