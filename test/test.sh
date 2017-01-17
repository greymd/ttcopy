#!/bin/bash
TEST_DIR="$(dirname $0)"
. "${TEST_DIR}/../wpb.sh"

test_simple_text () {
    echo aaaa | wpbcopy
    assertEquals 0 $?
    # assertEquals "aaaa" "$(wpbpaste)"
}

. ${TEST_DIR}/shunit2/src/shunit2
