#!/usr/bin/env bash
set -euo pipefail

# function to print colored text
print_color_text() {
    local timestamp
    local message

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    message="${2:-}"

    case "$1" in
    fail)
        echo -e "$timestamp \033[31m[  FAILURE  ]\033[0m $message"
        ;;
    ok)
        echo -e "$timestamp \033[32m[  SUCCESS  ]\033[0m $message"
        ;;
    warn)
        echo -e "$timestamp \033[33m[  WARNING  ]\033[0m $message"
        ;;
    info)
        echo -e "$timestamp \033[34m[INFORMATION]\033[0m $message"
        ;;
    *)
        echo -e "$timestamp [  NOTICE  ] $message"
        ;;
    esac
}

echo "========================================================================================="
print_color_text "info" "Welcome to ECI's Continuous Integration Test Suite."
echo "========================================================================================="

run_template_smoke_test() {
    if [ ! -d ./src ]; then
        print_color_text "fail" "Missing src directory."
        return 1
    fi

    print_color_text "warn" "Running template smoke test only. Replace this with project-specific tests."
    echo "Template smoke test passed." > ./src/out.src_tests
    touch out.src_test_success
}

echo "------------------------------------------------------------------------"
print_color_text "info" "Running source code checks."

if ! run_template_smoke_test; then
    echo "------------------------------------------------------------------------"
    print_color_text "fail" "One or more checks have failed. Exiting..."
    echo "------------------------------------------------------------------------"
    rm -f out.src_test_success ./src/out.src_tests
    exit 1
fi

echo "------------------------------------------------------------------------"
cat ./src/out.src_tests

echo "------------------------------------------------------------------------"
print_color_text "ok" "All checks have passed."
echo "------------------------------------------------------------------------"

rm -f out.src_test_success ./src/out.src_tests
exit 0
