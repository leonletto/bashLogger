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
log_debug "This is another debug statement"

