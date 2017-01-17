#!/bin/bash
TEST_DIR="$(dirname $0)"
. "${TEST_DIR}/../wpb.sh"

WPB_ID=""
WPB_PASSWORD=""

setUp () {
    # Set random id/password
    WPB_ID="$(cat /dev/urandom | LANG=C tr -dc 'a-zA-Z0-9\-_' | fold -w 30 | head -n 1)"
    WPB_PASSWORD="$(cat /dev/urandom | LANG=C tr -dc 'a-zA-Z0-9\-_' | fold -w 30 | head -n 1)"
}

test_simple_string () {
    echo "aaaa" | tr -d '\n' | wpbcopy
    assertEquals 0 $?
    assertEquals "aaaa" "$(wpbpaste)"
}

test_include_new_lines () {
    seq 1 1024 | wpbcopy
    assertEquals 0 $?
    assertEquals "$(seq 1 1024)" "$(wpbpaste)"
}

test_binary () {
    cat "${TEST_DIR}/test_files/payload.bin" | wpbcopy
    assertEquals 0 $?
    assertEquals "QlpoOTFBWSZTWTX7JdMAAAb//9pAAAiACAHBEkIAUAghIIkACICIAQABaAAIBOUIAIgKIABUY0ZNNGRo0NA0NAGj1DGhkAMgBiaaaeoGmkYiiIQIWHvQwZmFwUky981qDhLwknTW5QY+o+dowG9tHw5YegAfi7kinChIGv2S6YA=" "$(wpbpaste | base64)"
}

. ${TEST_DIR}/shunit2/src/shunit2
