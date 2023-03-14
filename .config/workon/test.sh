#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
nocolor='\033[0m'

function test_successful {
    local test_name="$1"
    printf "${green}%-8s${nocolor} %-20s\n" "SUCCESS" "$test_name"
}

function test_failure {
    local test_name="$1"
    local message="$2"
    printf "${red}%-8s${nocolor} %-20s %s\n" "FAILURE" "$test_name" "$message"
}

WORKON_DIR="$(pwd)"
source workon.sh

for test in tests/*.sh; do
    source "$test"
    __test_init
    __test_run
    __test_clean
    unset __test_init
    unset __test_run
    unset __test_clean
done
