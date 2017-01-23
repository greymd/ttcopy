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
. "${TEST_DIR}/../ttcp.sh"

TTCP_CLIP_NET_NG="https://example.com"
TTCP_TRANSFER_SH_NG="https://example.com"

TTCP_ID=""
TTCP_PASSWORD=""

# It is called before each tests.
setUp () {
    # Set random id/password
    TTCP_ID="$(cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1)"
    TTCP_PASSWORD="$(cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1)"
}

# Mockserver for c1ip.net
# It returns url `http://example.com/URL404/file.txt`
# which is supposed to have 404 http status.
cl1pMockserver () {
    local port=$1
    printf "HTTP/1.0 200 Ok\n\nhttp://example.com/URL404/file.txt" | nc -l $port
}

test_copy_transfer_sh_dead () {
    echo "aaaa" | tr -d '\n' | TTCP_TRANSFER_SH="$TTCP_TRANSFER_SH_NG" ttcopy
    assertEquals 128 $?
}

test_copy_clip_net_dead () {
    echo "aaaa" | tr -d '\n' | TTCP_CLIP_NET="$TTCP_CLIP_NET_NG" ttcopy
    assertEquals 129 $?
}

test_paste_clip_net_dead () {
    TTCP_CLIP_NET="$TTCP_CLIP_NET_NG" ttpaste
    assertEquals 129 $?
}

# `netcat` is necessary to run this test.
test_paste_transfer_sh_dead () {
    local port=10000
    # Run mock server to simulate c1ip.net with 10000 port.
    cl1pMockserver $port > /dev/null 2>&1 &
    TTCP_CLIP_NET="http://localhost:$port" TTCP_TRANSFER_SH="http://example.com" ttpaste
    assertEquals 128 $?
}

test_lack_dependency () {
    # It fails, if there is `hogehogeoppaipai` command.
    echo aaa | _TTCP_DEPENDENCIES="hogehogeoppaipai curl" ttcopy
    assertEquals 255 $?
}

test_unset_id () {
    echo aaa | TTCP_ID="" ttcopy
    assertEquals 255 $?
}

test_unset_password () {
    echo aaa | TTCP_PASSWORD="" ttcopy
    assertEquals 255 $?
}

test_simple_string () {
    echo "aaaa" | tr -d '\n' | ttcopy
    assertEquals 0 $?
    assertEquals "aaaa" "$(ttpaste)"
}

test_include_whitespaces () {
    echo "aaa bbb ccc" | ttcopy
    assertEquals 0 $?
    assertEquals "aaa bbb ccc" "$(ttpaste)"
}

test_multiple_paste () {
    echo "bbbb" | ttcopy
    assertEquals 0 $?

    # First time
    assertEquals "bbbb" "$(ttpaste)"

    # Second time
    assertEquals "bbbb" "$(ttpaste)"

    # Third time
    assertEquals "bbbb" "$(ttpaste)"
}

test_include_new_lines () {
    seq 1 256 | ttcopy
    assertEquals 0 $?
    assertEquals "$(seq 1 256)" "$(ttpaste)"
}

test_binary () {
    cat "${TEST_DIR}/test_files/payload.bin" | ttcopy
    assertEquals 0 $?
    # Compare binary data with hex string.
    assertEquals "425a6839314159265359a35cdf9b000005efffd840080180810400004018012009000a84084180001280800900088020002000318d31184698000031a7a40f5034f51a64d1faa66a3586c2b68499c88e307b7972b913e06f964b300289ad17f177245385090a35cdf9b0" "$(ttpaste | od -tx1 -An | tr -dc '[:alnum:]')"
}

. ${TEST_DIR}/shunit2/src/shunit2
