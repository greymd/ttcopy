#!/bin/bash

if [ -n "$ZSH_VERSION" ]; then
  # This is zsh
  echo "Testing for zsh $ZSH_VERSION"
  # Following two lines are necessary to run shuni2 with zsh
  SHUNIT_PARENT="$0"
  setopt shwordsplit
elif [ -n "$BASH_VERSION" ]; then
  # This is bash
  echo "Testing for bash $BASH_VERSION"
fi

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"
. "${TEST_DIR}/../wpb.sh"

CLIP_NET_NG="https://example.com"
TRANSFER_SH_NG="https://example.com"

WPB_ID=""
WPB_PASSWORD=""

setUp () {
    # Set random id/password
    WPB_ID="$(cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1)"
    WPB_PASSWORD="$(cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1)"
}

test_copy_transfer_sh_dead () {
    echo "aaaa" | tr -d '\n' | TRANSFER_SH="$TRANSFER_SH_NG" wpbcopy
    assertEquals 128 $?
}

test_copy_clip_net_dead () {
    echo "aaaa" | tr -d '\n' | CLIP_NET="$CLIP_NET_NG" wpbcopy
    assertEquals 129 $?
}

test_paste_clip_net_dead () {
    CLIP_NET="$CLIP_NET_NG" wpbpaste
    assertEquals 129 $?
}

# FIXME: There's no way to change `TRANS_URL` got from cl1p, so we cannot
#        the the case the transfer.sh was gone during pasting
# test_paste_transfer_sh_dead () {
#     ...
# }

test_lack_dependency () {
    local errMsg=$(echo aaa | DEPENDENCIES="hoge curl" wpbcopy 2>&1 )
    assertEquals 255 $?
}

test_simple_string () {
    echo "aaaa" | tr -d '\n' | wpbcopy
    assertEquals 0 $?
    assertEquals "aaaa" "$(wpbpaste)"
}

test_include_whitespaces () {
    echo "aaa bbb ccc" | wpbcopy
    assertEquals 0 $?
    assertEquals "aaa bbb ccc" "$(wpbpaste)"
}

test_multiple_paste () {
    echo "bbbb" | wpbcopy
    assertEquals 0 $?

    # First time
    assertEquals "bbbb" "$(wpbpaste)"

    # Second time
    assertEquals "bbbb" "$(wpbpaste)"

    # Third time
    assertEquals "bbbb" "$(wpbpaste)"
}

test_include_new_lines () {
    seq 1 256 | wpbcopy
    assertEquals 0 $?
    assertEquals "$(seq 1 256)" "$(wpbpaste)"
}

test_binary () {
    cat "${TEST_DIR}/test_files/payload.bin" | wpbcopy
    assertEquals 0 $?
    # Compare binary data with hex string.
    assertEquals "425a6839314159265359a35cdf9b000005efffd840080180810400004018012009000a84084180001280800900088020002000318d31184698000031a7a40f5034f51a64d1faa66a3586c2b68499c88e307b7972b913e06f964b300289ad17f177245385090a35cdf9b0" "$(wpbpaste | od -tx1 -An | tr -dc '[:alnum:]')"
}

. ${TEST_DIR}/shunit2/src/shunit2
