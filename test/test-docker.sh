#!/bin/bash

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%N}}")"; pwd)"

CONTAINER_OS="${CONTAINER_OS:-centos}"
CONTAINER_TAG="${CONTAINER_TAG:-latest}"
TEST_CONTAINER="$CONTAINER_OS:ttcopy_test"
DOCKER_FILE_PATH="$TEST_DIR/dockerfiles/$CONTAINER_OS/Dockerfile"
cat $DOCKER_FILE_PATH \
    | sed "s/@@@TAG_NAME@@@/$CONTAINER_TAG/" \
    | docker build -t $TEST_CONTAINER -

echo "# --------------------"
echo "# Docker container info"
echo "# --------------------"
cat $DOCKER_FILE_PATH \
    | sed "s/@@@TAG_NAME@@@/$CONTAINER_TAG/"
echo
_cmd="docker run -i --rm $TEST_CONTAINER uname -a"
echo $_cmd
$_cmd

echo "# --------------------"
echo "# curl version"
echo "# --------------------"
docker run -i --rm $TEST_CONTAINER curl --version

echo "# --------------------"
echo "# openssl version"
echo "# --------------------"
docker run -i --rm $TEST_CONTAINER openssl version

ttcopy () {
    docker run -i --rm -v "${TEST_DIR}/../":/usr/local $TEST_CONTAINER ttcopy "$@"
}

ttpaste () {
    docker run -i --rm -v "${TEST_DIR}/../":/usr/local $TEST_CONTAINER ttpaste "$@"
}

# It is called before each tests.
setUp () {
    # Set random id/password
    export TTCP_ID="$(cat /dev/urandom | grep -ao '[a-zA-Z0-9]' | tr -d '\n' | fold -w 128 | head -n 1)"
    export TTCP_PASSWORD="$(cat /dev/urandom | grep -ao '[a-zA-Z0-9]' | tr -d '\n' | fold -w 128 | head -n 1)"
    echo ">>>>>>>>>>" >&2
}

# It is called after each tests.
tearDown(){
    echo >&2
    echo "<<<<<<<<<<" >&2
    echo >&2
}

test_simple_string () {
    echo "aaaa" | tr -d '\n' | ttcopy -i $TTCP_ID -p $TTCP_PASSWORD
    assertEquals 0 $?
    assertEquals "aaaa" "$(ttpaste -i $TTCP_ID -p $TTCP_PASSWORD)"
}

test_include_whitespaces () {
    echo "aaa bbb ccc" | ttcopy -i $TTCP_ID -p $TTCP_PASSWORD
    assertEquals 0 $?
    assertEquals "aaa bbb ccc" "$(ttpaste -i $TTCP_ID -p $TTCP_PASSWORD)"
}

test_include_new_lines () {
    seq 1 256 | ttcopy -i $TTCP_ID -p $TTCP_PASSWORD
    assertEquals 0 $?
    assertEquals "$(seq 1 256)" "$(ttpaste -i $TTCP_ID -p $TTCP_PASSWORD)"
}

. ${TEST_DIR}/shunit2/src/shunit2
