#!/bin/bash

function __test_init {
    function test_new_profile {
        test_successful ${FUNCNAME[0]}
        test_failure ${FUNCNAME[0]} "just a test"
    }
}

function __test_run {
    test_new_profile
}

function __test_clean {
    unset test_new_profile
}

