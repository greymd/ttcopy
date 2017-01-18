#!/bin/bash

if [ -n "$ZSH_VERSION" ]; then
  # This is zsh
  echo "Testing for zsh $ZSH_VERSION"
  SHUNIT_PARENT=$0
  setopt shwordsplit
elif [ -n "$BASH_VERSION" ]; then
  # This is bash
  echo "Testing for bash $BASH_VERSION"
fi

TEST_DIR="$(dirname $0)"
. "${TEST_DIR}/../wpb.sh"

WPB_ID=""
WPB_PASSWORD=""

setUp () {
    # Set random id/password
    WPB_ID="$(cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1)"
    WPB_PASSWORD="$(cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1)"
}

test_simple_string () {
    echo "aaaa" | tr -d '\n' | wpbcopy
    assertEquals 0 $?
    assertEquals "aaaa" "$(wpbpaste)"
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
