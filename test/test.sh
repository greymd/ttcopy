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
. "${TEST_DIR}/../ttcp_activate.sh"

TTCP_CLIP_NET_NG="https://example.com"
TTCP_TRANSFER_SH_NG="https://example.com"

export TTCP_ID=""
export TTCP_PASSWORD=""

# Docker container which is used for proxy server.
readonly CONTAINER_NAME="ttcopy-test-proxy"
readonly DOCKER_HUB_REPOSITORY="greymd/$CONTAINER_NAME"

# It is called before each tests.
setUp () {
    # Set random id/password
    export TTCP_ID="$(cat /dev/urandom | grep -ao '[a-zA-Z0-9]' | tr -d '\n' | fold -w 128 | head -n 1)"
    export TTCP_PASSWORD="$(cat /dev/urandom | grep -ao '[a-zA-Z0-9]' | tr -d '\n' | fold -w 128 | head -n 1)"
}

# Mockserver for c1ip.net
# Create proxy server with squid.
# Q. Why `nc` is not used for it?
# A. `nc` does not support proxy fowarding with HTTPS protocol.
createProxyServer() {
    # If there is no "greymd/ttcopy-test-proxy" image, pull it.
    if ! ( docker images --format '{{.Repository}}' | grep -qE "^${DOCKER_HUB_REPOSITORY}$" ); then
        docker pull ${DOCKER_HUB_REPOSITORY}
    fi
    docker run -d --name $CONTAINER_NAME -p 3128:3128 ${DOCKER_HUB_REPOSITORY} > /dev/null
    sleep 10 # Wait proxy server starts safely.
}

killProxyServer() {
    # Surpress all the log & error messages
    docker kill $CONTAINER_NAME  &> /dev/null
    docker rm $CONTAINER_NAME  &> /dev/null
}
# It returns url `http://example.com/URL404/file.txt`
# which is supposed to have 404 http status.
cl1pMockserver () {
    local port=$1
    # How to create it
    # $ source lib/ttcp
    # $ TTCP_PASSWORD="aaa"
    # $ TTCP_SALT1="bbb"
    # $ echo "http://example.com/URL404/file.txt" | __ttcp::encode "$(echo "${TTCP_PASSWORD}${TTCP_SALT1}" | __ttcp::hash)" | __ttcp::base64enc
    local url404="yJCQtv32TUTdk_hBCvS6qBq_Apu7JWkhqgJdZMsjhAuYGwRaUJRVArqhO4IVxgcAiWo1ZDtWP_xdTs4PJmxu8Q=="
    printf "HTTP/1.0 200 Ok\n\nTTCP[$url404]" | nc -l $port
}

# Generate dummy data
dummyString () {
    cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1
}

test_proxy () {
    # If there is not docker on this machine, this test will be skipped.
    if (type docker); then
        # Kill container just in case
        killProxyServer
        createProxyServer

        # Try copy with proxy
        seq 10 | TTCP_PROXY="localhost:3128" ttcopy
        assertEquals 0 $?

        # Try paste with proxy
        assertEquals "$( seq 10 )" "$( TTCP_PROXY="localhost:3128" ttpaste )"

        killProxyServer
    else
       echo "Skip test_proxy because there is no docker on this host." >&2
    fi
}

# Try to use stopped proxy
test_proxy_failed () {
    # Kill containers just in case.
    killProxyServer

    seq 10 | TTCP_PROXY="localhost:3128" ttcopy
    assertEquals 16 $?

    TTCP_PROXY="localhost:3128" ttpaste
    assertEquals 17 $?
}

test_activator_dont_create_dupulicate_entry () {
    local oldPATH="$PATH"
    . "${TEST_DIR}/../ttcp_activate.sh"

    # As $_TTCP_DIR is already in the $PATH, so the activator should not do
    # anything. Here we check $PATH got no modification.
    assertEquals "$oldPATH" "$PATH"
}

test_failure_encoding () {
    # openssl command stops with something wrong.
    seq 5 10 | _TTCP_ENCRYPT_ALGORITHM="dummy-encoding" ttcopy -i hoge -p hoge 2>/dev/null
    assertEquals 7 $?
}

test_failure_decoding () {
    # Password is wrong.
    seq 5 10 | ttcopy -i myid -p mypass
    ttpaste -i myid -p wrong_pass
    assertEquals 8 $?

    # First time is ok, but second time is wrong.
    # This test ensures retrieved content is cached with encryption.
    seq 5 10 | ttcopy -i myid -p mypass
    ttpaste -i myid -p mypass > /dev/null
    assertEquals 0 $?
    ttpaste -i myid -p wrong_pass > /dev/null
    assertEquals 8 $?

    # First time is wrong, but second time is ok.
    # This test ensures retrieved url is cached with encryption.
    seq 5 10 | ttcopy -i myid -p mypass
    ttpaste -i myid -p wrong_pass > /dev/null
    assertEquals 8 $?
    ttpaste -i myid -p mypass > /dev/null
    assertEquals 0 $?

    # First time is wrong, then upload new stuff, and second time is ok.
    # This test ensures NOT to use the local url cache for new content.
    seq 5 10 | ttcopy -i myid -p mypass
    ttpaste -i myid -p wrong_pass > /dev/null
    assertEquals 8 $?
    echo "new content" | ttcopy -i myid -p mypass
    assertEquals "new content" "$(ttpaste -i myid -p mypass)"
    assertEquals 0 $?

    # After fail of decryption, try with different id.
    # This test ensures NOT to use the local url cache for different user.
    seq 5 10 | ttcopy -i myid -p mypass
    ttpaste -i myid -p wrong_pass > /dev/null
    assertEquals 8 $?
    ttpaste -i different_id -p mypass
    assertEquals 5 $? # Nothing should be copied.
}

test_copy_transfer_sh_dead () {
    echo "aaaa" | tr -d '\n' | TTCP_TRANSFER_SH="$TTCP_TRANSFER_SH_NG" ttcopy
    assertEquals 16 $?
}

test_copy_clip_net_dead () {
    echo "aaaa" | tr -d '\n' | TTCP_CLIP_NET="$TTCP_CLIP_NET_NG" ttcopy
    assertEquals 17 $?
}

test_paste_clip_net_dead () {
    TTCP_CLIP_NET="$TTCP_CLIP_NET_NG" ttpaste
    assertEquals 17 $?
}

# `netcat` is necessary to run this test.
test_paste_transfer_sh_dead () {
    local port=10000
    # Run mock server to simulate c1ip.net with 10000 port.
    cl1pMockserver $port > /dev/null 2>&1 &
    TTCP_PASSWORD="aaa" TTCP_SALT1="bbb" TTCP_CLIP_NET="http://localhost:$port" TTCP_TRANSFER_SH="http://example.com" ttpaste
    assertEquals 16 $?
}

test_lack_dependency () {
    # It fails, if there is `hogehogeoppaipai` command.
    echo aaa | _TTCP_DEPENDENCIES="hogehogeoppaipai curl" ttcopy
    assertEquals 127 $?
}

test_unset_id () {
    echo aaa | TTCP_ID="" ttcopy
    assertEquals 3 $?
}

test_unset_password () {
    echo aaa | TTCP_PASSWORD="" ttcopy
    assertEquals 3 $?
}

test_version () {
    # Version number consists major.minor.patch
    ttcopy -V | grep -E '[0-9]+\.[0-9]+\.[0-9]+'
    assertEquals 0 $?
    ttcopy --version | grep -E '[0-9]+\.[0-9]+\.[0-9]+'
    assertEquals 0 $?
    ttpaste -V | grep -E '[0-9]+\.[0-9]+\.[0-9]+'
    assertEquals 0 $?
    ttpaste --version | grep -E '[0-9]+\.[0-9]+\.[0-9]+'
    assertEquals 0 $?
    # Same version
    assertEquals "$(ttcopy -V)" "$(ttpaste -V)"
}

test_usage () {
    ttcopy -h | grep -E 'Usage: ttcopy'
    assertEquals 0 $?
    ttcopy --help | grep -E 'Usage: ttcopy'
    assertEquals 0 $?
    ttpaste -h | grep -E 'Usage: ttpaste'
    assertEquals 0 $?
    ttpaste --help | grep -E 'Usage: ttpaste'
    assertEquals 0 $?
}

# Do not be sensitive.
# This test case can easily be increased.
test_option_combination () {
    # help + other option
    ttcopy -hp hogehoge | grep -E 'Usage: ttcopy'
    assertEquals 0 $?

    # Help + other option
    ttcopy --help -p password -i sample | grep -E 'Usage: ttcopy'
    assertEquals 0 $?

    # version + password + id + help
    ttcopy -V --help -p password -i sample | grep -E '[0-9]+\.[0-9]+\.[0-9]+'
    assertEquals 0 $?

    # Undefined option
    ttcopy -Z
    assertEquals 4 $?

    # Undefined options + valid options
    seq 10 | ttcopy -Z --help -p password -i sample
    assertEquals 4 $?

    # Undefined argument
    ttcopy foobar
    assertEquals 4 $?

    # Undefined option
    ttpaste -Z
    assertEquals 4 $?

    # Undefined options + valid options
    seq 10 | ttpaste -Z --help -p password -i sample
    assertEquals 4 $?

    # Undefined argument
    ttpaste foobar
    assertEquals 4 $?
}

test_id_pass_given_by_arg () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    local NEW_ID_1="$(dummyString)"
    local NEW_PASSWORD_1="$(dummyString)"
    local NEW_ID_2="$(dummyString)"
    local NEW_PASSWORD_2="$(dummyString)"

    # Short option
    echo 'I have a pen.' | ttcopy -i $NEW_ID_1 -p $NEW_PASSWORD_1
    assertEquals 0 $?
    assertEquals "I have a pen." "$(ttpaste -i "$NEW_ID_1" -p "$NEW_PASSWORD_1")"
    assertEquals "I have a pen." "$(ttpaste -i "$NEW_ID_1" -p "$NEW_PASSWORD_1")"

    # Long option
    echo "I have an apple." | ttcopy --id="$NEW_ID_2" --password="$NEW_PASSWORD_2"
    assertEquals 0 $?
    assertEquals "I have an apple." "$(ttpaste --id="$NEW_ID_2" --password="$NEW_PASSWORD_2")"
    assertEquals "I have an apple." "$(ttpaste --id="$NEW_ID_2" --password="$NEW_PASSWORD_2")"

    assertNotEquals "$(ttpaste -i "$NEW_ID_1" -p "$NEW_PASSWORD_1")" "$(ttpaste -i "$NEW_ID_2" -p "$NEW_PASSWORD_2")"

    # Short & Long option
    echo "I have a pen." | ttcopy -i "$NEW_ID_1" --password="$NEW_PASSWORD_1"
    assertEquals 0 $?
    assertEquals "I have a pen." "$(ttpaste -i "$NEW_ID_1" --password="$NEW_PASSWORD_1")"
    assertEquals "I have a pen." "$(ttpaste -i "$NEW_ID_1" --password="$NEW_PASSWORD_1")"

    # Long & Short option
    echo "I have a pineapple." | ttcopy --id="$NEW_ID_2" --password="$NEW_PASSWORD_2"
    assertEquals 0 $?
    assertEquals "I have a pineapple." "$(ttpaste --id="$NEW_ID_2" --password="$NEW_PASSWORD_2")"
    assertEquals "I have a pineapple." "$(ttpaste --id="$NEW_ID_2" --password="$NEW_PASSWORD_2")"

    assertNotEquals "$(ttpaste -i "$NEW_ID_1" -p "$NEW_PASSWORD_1")" "$(ttpaste -i "$NEW_ID_2" -p "$NEW_PASSWORD_2")"

    # Password is defined by the variable.
    TTCP_ID=""
    TTCP_PASSWORD="$(dummyString)"
    echo "Apple Pen" | ttcopy -i "$NEW_ID_1"
    assertEquals 0 $?
    assertEquals "Apple Pen" "$(ttpaste -i "$NEW_ID_1")"

    # ID is defined by the variable.
    TTCP_ID="$(dummyString)"
    TTCP_PASSWORD=""
    echo "Pineapple Pen" | ttcopy -p "$NEW_PASSWORD_1"
    assertEquals 0 $?
    assertEquals "Pineapple Pen" "$(ttpaste -p "$NEW_PASSWORD_1")"
}

test_id_pass_given_by_arg_error () {
    TTCP_ID=""
    TTCP_PASSWORD=""

    # Short option: password is empty
    echo AAA | ttcopy -i "dummy"
    assertEquals 3 $?

    # Long option: password is empty
    echo AAA | ttcopy --id=dummy
    assertEquals 3 $?

    # Short option: ID is empty
    echo AAA | ttcopy -p dummy
    assertEquals 3 $?

    # Long option: ID is empty
    echo AAA | ttcopy --password=dummy
    assertEquals 3 $?

    # Short option: password is empty
    ttpaste -i dummy
    assertEquals 3 $?

    # Long option: password is empty
    ttpaste --id=dummy
    assertEquals 3 $?

    # Short option: ID is empty
    ttpaste -p dummy
    assertEquals 3 $?

    # Long option: ID is empty
    ttpaste --password=dummy
    assertEquals 3 $?
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
