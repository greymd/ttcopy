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
readonly DOCKER_HUB_REPOSITORY="sameersbn/squid"

# It is called before each tests.
setUp () {
    # Set random id/password
    export TTCP_ID="$(cat /dev/urandom | grep -ao '[a-zA-Z0-9]' | tr -d '\n' | fold -w 128 | head -n 1)"
    export TTCP_PASSWORD="$(cat /dev/urandom | grep -ao '[a-zA-Z0-9]' | tr -d '\n' | fold -w 128 | head -n 1)"
    # Use SHUNIT_TMPDIR instead of TMPDIR as much as possible.
    # TMPDIR does not work on particular environments.
    export _TTCP_USER_HOME="${SHUNIT_TMPDIR}"
    # Delete in advance
    rm -rf "$_TTCP_USER_HOME/.ttcopy"
    echo ">>>>>>>>>>" >&2
}

# It is called after each tests.
tearDown(){
    echo >&2
    echo "<<<<<<<<<<" >&2
    echo >&2
}

# Create proxy server with squid.
# Q. Why `nc` is not used for it?
# A. `nc` does not support proxy fowarding with HTTPS protocol.
createProxyServer() {
    docker run -d --name $CONTAINER_NAME -p 3128:3128 ${DOCKER_HUB_REPOSITORY} > /dev/null
    sleep 10 # Wait proxy server starts safely.
}

# Generate dummy data
randomString () {
    cat /dev/urandom | strings | grep -o '[[:alnum:]]' | tr -d '\n' | fold -w 128 | head -n 1
}

ID_PREFIX="$(randomString)"

# Create id with the prefix which is unique for each test session.
# So the test using same id will not conflict even if they run in parallel.
genId() {
    local id="$1"
    echo "${ID_PREFIX}${id}"
}

killProxyServer() {
    # Surpress all the log & error messages
    docker kill $CONTAINER_NAME  &> /dev/null
    docker rm $CONTAINER_NAME  &> /dev/null
}

# Mockserver for cl1p.net
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

# Simulate first screen to enter id and passwords.
# Usage:
# simulateinitializer <ID> <Password> <Password(second time)> <command to show the screen>
# @return(stdout) -- print results of given command.
# @return(exit status) -- Same exit status of given command.
simulateInitializer () {
    if ! (type expect &> /dev/null); then
        echo "'expect' is required." >&2
        echo "Skip this test." >&2
        return 255
    fi

    local _id="$1"
    local _password1="$2"
    local _password2="$3"
    local _cmd="$4"
    local _execution="${SHUNIT_TMPDIR}/execution"
    local _exit_status=""
    local _exit_status_store="${SHUNIT_TMPDIR}/exit_status"
    local _shell="$SHELL"

    # Create a file which includes commands to be executed.
    echo "$_cmd"                           >  $_execution
    echo "echo \$? > $_exit_status_store"  >> $_execution
    # To prevent expect script from stopping immediately,
    # Print the end message.
    echo "echo 'End expect' >&2"           >> $_execution

    # Start simulation with "expect" script.
    expect -c "set timeout 60
    spawn $_shell $_execution
    expect \"Enter ID\" {
        send \"$_id\"
        send \"\\r\"
    }
    expect \"Enter password\" {
        send \"$_password1\"
        send \"\r\"
    }
    expect \"Enter same password\" {
        send \"$_password2\"
        send \"\r\"
    }
    expect \"End expect\"
    interact
    "

    _exit_status=$(cat "$_exit_status_store")
    rm -f "$_exit_status_store"
    rm -f "$_execution"
    return $_exit_status
}

#====================================
# Test functions
#====================================

test_ttcopy_first_time () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttcopy'
    assertEquals 124 $?
}

test_ttcopy_first_time_with_stdin () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'seq 10 | ttcopy'
    assertEquals 124 $?
}

test_ttpaste_first_time () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste'
    assertEquals 124 $?
}

test_ttcopy_unset_id () {
    TTCP_ID=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttcopy'
    assertEquals 124 $?
}

test_ttcopy_unset_id_stdin () {
    TTCP_ID=""
    simulateInitializer "$(genId myid)" "password" "password" 'seq 10 | ttcopy'
    assertEquals 124 $?
}

test_ttcopy_unset_password () {
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttcopy'
    assertEquals 124 $?
}

test_ttpaste_unset_id () {
    TTCP_ID=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste'
    assertEquals 124 $?
}

test_ttpaste_unset_password () {
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste'
    assertEquals 124 $?
}

test_ttcopy_unset_pass_opt_id () {
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'seq 10 | ttcopy -i myid'
    assertEquals 124 $?
}

test_ttcopy_unset_id_opt_pass () {
    TTCP_ID=""
    simulateInitializer "$(genId myid)" "password" "password" 'seq 10 | ttcopy -p mypass'
    assertEquals 124 $?
}

test_ttpaste_unset_pass_opt_id () {
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste -i myid'
    assertEquals 124 $?
}

test_ttpaste_unset_id_opt_pass () {
    TTCP_ID=""
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste -p mypass'
    assertEquals 124 $?
}

test_ttcopy_first_time_wrong_pass () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "wrong_password" 'ttcopy'
    assertEquals 6 $?
}

test_ttcopy_first_time_wrong_pass_stdin () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "wrong_password" 'seq 10 | ttcopy'
    assertEquals 6 $?
}

test_ttpate_first_time_wrong_pass () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    simulateInitializer "$(genId myid)" "password" "wrong_password" 'ttpaste'
    assertEquals 6 $?
}

test_ttcopy_init () {
    TTCP_ID="aaa"
    TTCP_PASSWORD="bbb"
    simulateInitializer "$(genId myid)" "password" "password" 'ttcopy --init'
    assertEquals 124 $?
}

test_ttpaste_init () {
    TTCP_ID="aaa"
    TTCP_PASSWORD="bbb"
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste --init'
    assertEquals 124 $?
}

test_init_multiple () {
    TTCP_ID="aaa"
    TTCP_PASSWORD="bbb"

    # First time
    simulateInitializer "$(genId myid)" "password" "password" 'ttcopy --init'
    assertEquals 124 $?

    # Second time
    simulateInitializer "$(genId myid)" "password" "password" 'ttpaste --init'
    assertEquals 124 $?
}

test_init_and_try () {
    local _myid="$(genId myid)"
    local _mypassword="$(randomString)"

    TTCP_ID=""
    TTCP_PASSWORD=""
    _TTCP_USER_HOME="${SHUNIT_TMPDIR}/try"

    # First time
    simulateInitializer "$_myid" "$_mypassword" "$_mypassword" 'ttcopy --init'

    seq 200 210 | ttcopy

    assertEquals "$(seq 200 210)" "$(ttpaste)"
    assertEquals "$(seq 200 210)" "$(ttpaste -i "$_myid" -p "$_mypassword")"

    rm -rf "$_TTCP_USER_HOME"
}

test_invalid_config_format () {
    local _myid="$(genId myid)"
    local _mypassword="$(randomString)"
    TTCP_ID=""
    TTCP_PASSWORD=""

    _TTCP_USER_HOME="${SHUNIT_TMPDIR}/invalid"

    # First time
    simulateInitializer "$_myid" "$_mypassword" "$_mypassword" 'ttcopy --init'
    assertEquals 124 $?

    # Delete one of the line
    cat "$_TTCP_USER_HOME/.ttcopy/config" | grep -Ev '^TTCP_ID_CLIP=.*$' > "$_TTCP_USER_HOME/.ttcopy/config_tmp"
    # Force delete. Because permission is read-only.
    rm -f "$_TTCP_USER_HOME/.ttcopy/config"
    mv "$_TTCP_USER_HOME/.ttcopy/config_tmp" "$_TTCP_USER_HOME/.ttcopy/config"

    # Initial screen will be displayd at the second time also.
    simulateInitializer "$_myid" "$_mypassword" "$_mypassword" 'seq 10 | ttcopy'
    assertEquals 124 $?

    rm -rf "$_TTCP_USER_HOME"
}

test_check_credential_priority () {
    local _id_conf="$(genId myid_conf)"
    local _password_conf="$(randomString)"

    local _id_env="$(genId myid_env)"
    local _password_env="$(randomString)"

    local _id_opt="$(genId myid_opt)"
    local _password_opt="$(randomString)"

    # Prepare ID/password environment variables.
    TTCP_ID="$_id_env"
    TTCP_PASSWORD="$_password_env"

    # Prepare config file
    _TTCP_USER_HOME="${SHUNIT_TMPDIR}/priority"
    simulateInitializer "$_id_conf" "$_password_conf" "$_password_conf" 'ttcopy --init'

    # Option is most prioritized.
    seq 100 200 | ttcopy -i "$_id_opt" -p "$_password_opt"
    assertEquals "$(seq 100 200)" "$(ttpaste -i "$_id_opt" -p "$_password_opt")"

    # If environment variables are available, use them.
    seq 100 250 | ttcopy
    assertEquals "$(seq 100 250)" "$(ttpaste -i "$_id_env" -p "$_password_env")"

    # If either environment variable is empty, use config file.
    TTCP_ID=""
    TTCP_PASSWORD="test"
    seq 100 300 | ttcopy
    assertEquals "$(seq 100 300)" "$(ttpaste -i "$_id_conf" -p "$_password_conf")"

    rm -rf "$_TTCP_USER_HOME"
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
    seq 5 10 | _TTCP_ENCRYPT_ALGORITHM="dummy-encoding" ttcopy -i $(genId hoge) -p hoge 2>/dev/null
    assertEquals 7 $?
}

test_failure_decoding () {
    # Password is wrong.
    seq 5 10 | ttcopy -i $(genId myid) -p mypass
    ttpaste -i $(genId myid) -p wrong_pass
    assertEquals 8 $?

    # First time is ok, but second time is wrong.
    # This test ensures retrieved content is cached with encryption.
    seq 5 10 | ttcopy -i $(genId myid) -p mypass
    ttpaste -i $(genId myid) -p mypass > /dev/null
    assertEquals 0 $?
    ttpaste -i $(genId myid) -p wrong_pass > /dev/null
    assertEquals 8 $?

    # First time is wrong, but second time is ok.
    # This test ensures retrieved url is cached with encryption.
    seq 5 10 | ttcopy -i $(genId myid) -p mypass
    ttpaste -i $(genId myid) -p wrong_pass > /dev/null
    assertEquals 8 $?
    ttpaste -i $(genId myid) -p mypass > /dev/null
    assertEquals 0 $?

    # First time is wrong, then upload new stuff, and second time is ok.
    # This test ensures NOT to use the local url cache for new content.
    seq 5 10 | ttcopy -i $(genId myid) -p mypass
    ttpaste -i $(genId myid) -p wrong_pass > /dev/null
    assertEquals 8 $?
    echo "new content" | ttcopy -i $(genId myid) -p mypass
    assertEquals "new content" "$(ttpaste -i $(genId myid) -p mypass)"
    assertEquals 0 $?

    # After fail of decryption, try with different id.
    # This test ensures NOT to use the local url cache for different user.
    seq 5 10 | ttcopy -i $(genId myid) -p mypass
    ttpaste -i $(genId myid) -p wrong_pass > /dev/null
    assertEquals 8 $?
    ttpaste -i $(genId different_id) -p mypass
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
    ttcopy --help -p password -i $(genId sample) | grep -E 'Usage: ttcopy'
    assertEquals 0 $?

    # version + password + id + help
    ttcopy -V --help -p password -i $(genId sample) | grep -E '[0-9]+\.[0-9]+\.[0-9]+'
    assertEquals 0 $?

    # Undefined option
    ttcopy -Z
    assertEquals 4 $?

    # Undefined options + valid options
    seq 10 | ttcopy -Z --help -p password -i $(genId sample)
    assertEquals 4 $?

    # Undefined argument
    ttcopy foobar
    assertEquals 4 $?

    # Undefined option
    ttpaste -Z
    assertEquals 4 $?

    # Undefined options + valid options
    seq 10 | ttpaste -Z --help -p password -i $(genId sample)
    assertEquals 4 $?

    # Undefined argument
    ttpaste foobar
    assertEquals 4 $?
}

test_id_pass_given_by_arg () {
    TTCP_ID=""
    TTCP_PASSWORD=""
    local NEW_ID_1="$(genId id1)"
    local NEW_PASSWORD_1="$(randomString)"
    local NEW_ID_2="$(randomString)"
    local NEW_PASSWORD_2="$(genId id2)"

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
    TTCP_PASSWORD="$(randomString)"
    echo "Apple Pen" | ttcopy -i "$NEW_ID_1"
    assertEquals 0 $?
    assertEquals "Apple Pen" "$(ttpaste -i "$NEW_ID_1")"

    # ID is defined by the variable.
    TTCP_ID="$(randomString)"
    TTCP_PASSWORD=""
    echo "Pineapple Pen" | ttcopy -p "$NEW_PASSWORD_1"
    assertEquals 0 $?
    assertEquals "Pineapple Pen" "$(ttpaste -p "$NEW_PASSWORD_1")"
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
