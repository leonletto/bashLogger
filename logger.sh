#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi

###SOF###logger.sh

##################################
#
# logger library for bash scripts
# Developed by: Leon Letto
# December 2022
#
# revision 1 (Jan 8, 2023)
#
# logger for bash scripts:
#
# This script is used to log messages to the console and to a log file and is designed to be similar the API of the python
# logging module.
#
#
##################################

#compare version numbers of two OS versions or floating point numbers including ascii characters
# From https://github.com/leonletto/bash_compare_numbers
compare_numbers() {
    #echo "Comparing $1 and $2"
    IFS='.' read -r -a os1 <<< "$1"
    IFS='.' read -r -a os2 <<< "$2"

    counter=0

    if [[ "${#os1[@]}" -gt "${#os2[@]}" ]]; then
        counter="${#os1[@]}"
    else
        counter="${#os2[@]}"
    fi

    for (( k=0; k<counter; k++ )); do

        # If the arrays are different lengths and we get to the end, then whichever array is longer is greater
        if [[ "${os1[$k]:-}" ]] && ! [[ "${os2[$k]:-}" ]]; then
            echo "gt"
            return 0
        elif [[ "${os2[$k]:-}" ]] && ! [[ "${os1[$k]:-}" ]]; then
            echo "lt"
            return 0
        fi

        if [[ "${os1[$k]}" != "${os2[$k]}" ]]; then
            t1="${os1[$k]}"
            t2="${os2[$k]}"

            alphat1=${t1//[^a-zA-Z]}; alphat1=${#alphat1}
            alphat2=${t2//[^a-zA-Z]}; alphat2=${#alphat2}

            # replace alpha characters with ascii value and make them smaller for comparison
            if [[ "$alphat1" -gt 0 ]]; then
                temp1=""
                for (( j=0; j<${#t1}; j++ )); do
                    if [[ ${t1:$j:1} = *[[:alpha:]]* ]]; then
                        g=$(LC_CTYPE=C printf '%d' "'${t1:$j:1}")
                        g=$((g-40))
                        temp1="$temp1$g"
                    else
                        temp1="$temp1${t1:$j:1}"
                    fi

                done
                t1="$temp1"
            fi
            # replace alpha characters with ascii value and make them smaller for comparison
            if [[ "$alphat2" -gt 0 ]]; then
                temp2=""
                for (( j=0; j<${#t2}; j++ )); do
                    if [[ ${t2:$j:1} = *[[:alpha:]]* ]]; then
                        g=$(LC_CTYPE=C printf '%d' "'${t2:$j:1}")
                        g=$((g-40))
                        temp2="$temp2$g"
                    else
                        temp2="$temp2${t2:$j:1}"
                    fi

                done
                t2="$temp2"
            fi

            if [[ "$t1" -gt "$t2" ]]; then
                echo "gt"
                return 0
            elif [[ "$t1" -lt "$t2" ]]; then
                echo "lt"
                return 0
            fi
        fi
    done

    echo "eq"
    return 0

}

# compares two numbers n1 > n2 including floating point numbers
gt() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "gt" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 > n2 including floating point numbers
lt() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "lt" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 >= n2 including floating point numbers
ge() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "gt" ]]; then
        return 0
    elif [[ "$result" == "eq" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 >= n2 including floating point numbers
le() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "lt" ]]; then
        return 0
    elif [[ "$result" == "eq" ]]; then
        return 0
    else
        return 1
    fi
}

# compares two numbers n1 == n2 including floating point numbers
eq() {
    result=$(compare_numbers "$1" "$2")
    if [[ "$result" == "eq" ]]; then
        return 0
    else
        return 1
    fi
}


fileSize() {
    # Returns the file size in bytes even if it is on a mapped drive
    optChar='f'
    fmtString='%z'
    stat -$optChar "$fmtString" "$@"
}


CRITICAL=0
ERROR=1
WARNING=2
INFO=3
DEBUG=4
#_log_levels=(CRITICAL ERROR WARNING INFO DEBUG)
_log_to_screen=true _log_to_file=false _log_file_name="" _log_color_output=true _log_level=3 _log_rotation_count=5 _log_file_rotate_size=100000

dateTime="$(date +%Y/%m/%d) $(date +%T%z)" # Date format: YYYY/MM/DD HH:MM:SS+0000

#dateForFileName=$(date +%Y%m%d)
#timeForFileName=$(date +%H%M%S)



#function to rotate logs when they reach a certain size automatically using standard numbering
rotateLogs() {
    local logFile="$1"
    local logFileBaseName="${logFile%.*}"
    local logFileExtension="${logFile##*.}"
    local logFileRotateSize=$_log_file_rotate_size # 100000 bytes = 100 kilobytes
    currentSize="$(fileSize "$logFile")"

    local numberOfRotatedLogs=_log_rotation_count

    if ge "${currentSize}" "${logFileRotateSize}"; then
        for ((i=numberOfRotatedLogs; i>-1; i--)); do
            if [ -f "${logFileBaseName}.${logFileExtension}.${i}" ]; then
                if [ "$i" -eq $((numberOfRotatedLogs)) ]; then
                    rm "${logFileBaseName}.${logFileExtension}.${i}"
                else
                    mv "${logFileBaseName}.${logFileExtension}.$((i))" "${logFileBaseName}.${logFileExtension}.$((i+1))"
                    touch "${logFileBaseName}.${logFileExtension}.$((i))"
                fi
            elif [ -f "${logFileBaseName}.${logFileExtension}" ] && [ "$i" -eq "0" ]; then
                mv "${logFileBaseName}.${logFileExtension}" "${logFileBaseName}.${logFileExtension}.$((i+1))"
                touch "${logFileBaseName}.${logFileExtension}"
            fi
        done
    fi

}

log_rotation_count() {
    _log_rotation_count=$1
}

log_file_rotate_size() {
    if [ -n "$_log_file_name" ] && [ "$1" -ne $_log_file_rotate_size ]; then
        echo "log_file_rotate_size must be set before log_file_name or new size will not be used"
    else
        _log_file_rotate_size=$1
    fi

}


log_color_output() {
    if [[ "$1" == "true" ]]
    then
        _log_color_output=true
    else
        _log_color_output=false
    fi
}

log_level() {
    local level
    level=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    case $level in
        CRITICAL)
            _log_level=0
            ;;
        ERROR)
            _log_level=1
            ;;
        WARNING)
            _log_level=2
            ;;
        INFO)
            _log_level=3
            ;;
        DEBUG)
            _log_level=4
            ;;
        *)
            echo "Invalid log level: $level"
            exit 1
            ;;
    esac
}

what_level(){
    local level
    case $3 in
        CRITICAL)
            level=$CRITICAL
            ;;
        ERROR)
            level=$ERROR
            ;;
        WARNING)
            level=$WARNING
            ;;
        INFO)
            level=$INFO
            ;;
        DEBUG)
            level=$DEBUG
            ;;
        *)
            level=$INFO
            ;;
    esac
    echo $level
}

log_to_screen() {
    if [[ "$1" == "True" || "$1" == "true"  ]]; then
        _log_to_screen=true
    elif [[ "$1" == "False" || "$1" == "false" ]]; then
        _log_to_screen=false
    fi
}

log_file_name() {
    _log_file_name=$1
    if [ -n "$_log_file_name" ]; then
        _log_to_file=true
        # check if a filename contains a path
        if [[ "${_log_file_name}" == */* ]]; then
            # if it does, then create the directory if it doesn't exist
            if [ ! -d "${_log_file_name%/*}" ]; then
                mkdir -p "${_log_file_name%/*}"
            fi
        fi
        if [[ ! -f "$_log_file_name" ]]; then
            touch "$_log_file_name"
        else
            rotateLogs "$_log_file_name"
        fi
    else
        _log_to_file=false
    fi

}

set_logging() {
    if ! [[ "${1:-}" ]]
    then
        echo 'No log level specified - _log_level set to INFO'
    else
        log_level "$1"
    fi
    if ! [[ "${2:-}" ]]
    then
        echo 'logging to screen by default enabled'
    else
        log_to_screen "$2"
    fi

    if ! [[ "${3:-}" ]]
    then
#        _log_file_name="./ws1AdminApiLog.log"
#        printf 'No log file specified therefore default filename %s is used.\n' "${_log_file_name}"
#        log_file_name "${_log_file_name}"
        printf 'No log file specified therefore logging is to screen only by default'

    else
        log_file_name "$3"
    fi

}



export COLOR_BOLD="\033[1m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;34m"
COLOR_YELLOW="\033[0;33m"
COLOR_BLUE="\033[0;32m"
COLOR_OFF="\033[0m"


log_color() {
    if ! [[ "${1:-}" ]]
    then
        local level=$_log_level
    else
        local level="$1"
    fi

    local color
    case $level in
        CRITICAL)
            color=$COLOR_RED
            ;;
        ERROR)
            color=$COLOR_RED
            ;;
        WARNING)
            color=$COLOR_YELLOW
            ;;
        INFO)
            color=$COLOR_OFF
            ;;
        DEBUG)
            color=$COLOR_GREEN
            ;;
        *)
            color=$COLOR_OFF
            ;;
    esac
    echo -e "$color"
}



print_message() {
    local message
    message="$(echo "$@" | cut -f 4- -d ' ')"
    if [[ "$_log_to_screen" == "true" ]]; then
        if [[ "$_log_color_output" == "true" ]]; then
            printf '%s%s %s %s %s %s' "$(log_color "$1")" "${dateTime}" "$2" "$3" "$1" "$message"
            printf '%s\n' "$(log_color)"
        else
            printf '%s %s %s %s %s' "${dateTime}" "$2" "$3" "$1" "$message"
            printf '\n'
        fi

    fi
    if [[ "$_log_to_file" == "true" ]]; then
        printf '%s %s %s %s %s' "${dateTime}" "$2" "$3" "$1" "$message" >> "$_log_file_name"
        printf '\n' >> "$_log_file_name"
    fi

}

shopt -s expand_aliases
#This is a hack to get around the fact that aliases are not exported
#when a script is sourced.  This is a workaround to get around that.
#These aliases allow showing the details of the command from the calling file and the line number
alias log_critical='logger_critical ${BASH_SOURCE##*/} $LINENO '
alias log_error='logger_error ${BASH_SOURCE##*/} $LINENO '
alias log_warning='logger_warning ${BASH_SOURCE##*/} $LINENO '
alias log_info='logger_info ${BASH_SOURCE##*/} $LINENO '
alias log_debug='logger_debug ${BASH_SOURCE##*/} $LINENO '
alias log_cat_file='logger_cat_file ${BASH_SOURCE##*/} $LINENO '
alias log_info_file='logger_info_file ${BASH_SOURCE##*/} $LINENO '
alias log_execute='logger_execute ${BASH_SOURCE##*/} $LINENO '

logger_critical() { if ge $_log_level $CRITICAL; then print_message CRITICAL "$@";fi  }
logger_error()    { if ge $_log_level $ERROR; then  print_message ERROR "$@"; fi    }
logger_warning()  { if ge $_log_level $WARNING; then  print_message WARNING "$@"; fi    }
logger_info()     { if ge $_log_level $INFO; then  print_message INFO "$@"; fi  }
logger_debug()    { if ge $_log_level $DEBUG; then  print_message DEBUG "$@"; fi    }

# functions for logging command output - Sample functions
logger_cat_file()   { if ge $_log_level $DEBUG && [[ -f $3 ]];then print_message DEBUG "$1" "$2" "=== contents of $3 start ===" && cat "$3" && print_message DEBUG "$1" "$2" "=== contents of $3 end ==="; fi }
logger_info_file()    { if ge $_log_level $INFO  && [[ -f $3 ]];then print_message INFO "$1" "$2" "=== file details of $3 start ===" && ls -l "$3" && print_message INFO "$1" "$2" "=== file details of $3 end ==="; fi }
logger_execute() {
    local message
    message="$(echo "$@" | cut -f 4- -d ' ')"
    local level
    case $3 in
        CRITICAL)
            level=$CRITICAL
            ;;
        ERROR)
            level=$ERROR
            ;;
        WARNING)
            level=$WARNING
            ;;
        INFO)
            level=$INFO
            ;;
        DEBUG)
            level=$DEBUG
            ;;
        *)
            level=$INFO
            ;;
    esac
    if ge $_log_level $level; then
        print_message "$3" "$1" "$2"  "=== output of $message start ==="
        "${@:4}"
        print_message "$3" "$1" "$2"  "=== output of $message end ==="
    else
        "${@:4}" >/dev/null
    fi
}

###EOF###logger.sh