#!/bin/bash

# function to print colored text
print_color_text() {
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    case $1 in
    fail)
        echo -e "$timestamp \033[31m[  FAILURE  ]\033[0m $2"
        ;;
    ok)
        echo -e "$timestamp \033[32m[  SUCCESS  ]\033[0m $2"
        ;;
    warn)
        echo -e "$timestamp \033[33m[  WARNING  ]\033[0m $2"
        ;;
    info)
        echo -e "$timestamp \033[34m[INFORMATION]\033[0m $2"
        ;;
    *)
        echo -e "$timestamp [  NOTICE  ] $2"
        ;;
    esac
}
echo "========================================================================================="
print_color_text "info" "Welcome to ECI's Continuous Integration Test Suite."
echo "========================================================================================="
run_tests() {
    cd ./src || exit 1
    echo "Great work! The template test was successful!!!" > out.src_tests
    cd ..
    touch out.src_test_success
}
echo "------------------------------------------------------------------------"
print_color_text "info" "Running the source code tests."
run_tests &
sleep 1
echo "------------------------------------------------------------------------"
wait
cat ./src/out.src_tests
if [ ! -f out.src_test_success ]; then
    echo "------------------------------------------------------------------------"
    print_color_text "fail" "One or more tests have failed. Exiting..."
    echo "------------------------------------------------------------------------"
    exit 1
else
    echo "------------------------------------------------------------------------"
    print_color_text "ok" "All tests have passed! You are good to go!"
    echo "------------------------------------------------------------------------"
    rm -f out.src_test_success ./src/out.src_tests
    exit 0
fi
