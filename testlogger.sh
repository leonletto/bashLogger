#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

. ./logger.sh
# Test Log rotation using size
#log_file_rotate_size 2000
#log_file_name "testlogger.log"

log_info "-------------starting run on $(date)--------------"
log_critical "This is a critical error"
log_error "This is an error"
log_warning "This is a warning"
log_info "This is a info log"
log_debug "This is a debug statement"
log_execute INFO ls -l
date &> /tmp/date.out
log_cat_file /tmp/date.out
log_info_file /tmp/date.out
log_level DEBUG
log_debug "This is a debug statement"

# Tests log rotation using size
log_info "now test log rotation using size"
test_log_file_name="testlogger.log"
log_file_rotate_size 500
log_file_name $test_log_file_name
rm -f testlogger.log*
log_to_screen "false"
test_message_new_file='This should should be in the first message in the new log file'
log_info "This is a info log to test the log file rotation size 500 is working and this is a long line to test the log file rotation size 500 is working"
log_info "This is a info log to test the log file rotation size 500 is working and this is a long line to test the log file rotation size 500 is working"
log_info "this is a message to show log rotation only happens over 500 bytes"
rotateLogs $test_log_file_name # Rotation should not happen with this call
log_info "This is a info log to test the log file rotation and this message should be the last line in the rotated log file testlogger.log.1"
rotateLogs $test_log_file_name # Rotation should happen with this call
log_info "$test_message_new_file"
log_to_screen "true"
if [[ -f "testlogger.log.1" ]]; then
    log_file_name ""
    # compare contents of testlogger.log to test_message_new_file to make sure the last line is the message we expect
    test_file_contents=$(tail -n 1 testlogger.log)
    bad_test_message="bad1"
    if [[ $test_file_contents =~ ${bad_test_message} ]]; then
        echo "Something is wrong with testing file contents"
    fi
    if [[ $test_file_contents =~ $test_message_new_file ]]; then
        log_info "testlogger.log.1 exists and log rotation is working"
        rm -f testlogger.log*
    else
        log_error "Log rotation using size is not working properly"
    fi
else
    log_error "testlogger.log.1 does not exist therefore log rotation using size is not working"
fi

