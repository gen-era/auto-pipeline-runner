#!/usr/bin/bash
# Check file modifications

# https://sharats.me/posts/shell-script-best-practices/


# [[file:docs/auto_pipeline_runner.org::*Check file modifications][Check file modifications:1]]
set -o errexit
set -o nounset
set -o pipefail

if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi


usage() {
    echo 'Usage: check_file_modification.sh [OPTIONS] input_dir

Description:
This script checks if any file in the specified input directory has been modified within a certain period. It compares the last modified time and size of a file before and after a delay, and confirms if there were no changes during that time.

Options:
-h, --help          Display this help message and exit.
-V, --version       Show version and exit.

Arguments:
-d --dir           The directory path where files are located. This directory will be scanned for files to check for modification.
-i --interval      The inverval for which the checking for the modification will be performed. Default is 5 seconds.

Example:
./check_file_modification.sh /path/to/input_directory

This command will check if any file in the specified input directory (/path/to/input_directory) has been modified within a certain period.
'
}

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    usage
    exit
fi

# cd "$(dirname "$0")"

PARSED_ARGUMENTS=$(getopt -a -o d:i: -l dir:,interval: -- "$@")
VALID_ARGUMENTS=$?
if [ "$VALID_ARGUMENTS" != "0" ]; then
    usage
fi

interval=5

eval set -- "$PARSED_ARGUMENTS"
while :; do
    case "$1" in
    -d | --dir)
        input_dir="$2"
        shift 2
        ;;
    -i | --interval)
        interval="$2"
        shift 2
        ;;
    -h | --help)
        usage
        ;;
    -V )
        echo "v0.0.1"
        exit
        ;;
    # -- means the end of the arguments; drop this, and break out of the while loop
    --)
        shift
        break
        ;;
    # If invalid options were passed, then getopt should have reported an error,
    # which we checked as VALID_ARGUMENTS when getopt was called...
    *)
        echo "Unexpected option: $1 - this should not happen."
        usage
        ;;
    esac
done

if [ -z "${input_dir:-}" ]; then
    usage;
    exit 1;
fi

# Check file modifications:1 ends here


# get last modified file

# This function get the last modified file modified from https://www.baeldung.com/linux/recently-changed-files.
# Find command finds all the files with =-type f= and prints the last modified date with =%T@= as seconds till Jan 1970.
# The files are sorted as numeric seconds.
# Last modified file is selected with =tail=.
# Path of the file is gathered with =cut=.


# [[file:docs/auto_pipeline_runner.org::*get last modified file][get last modified file:1]]
get_last_modified_file() {
    echo $(find $input_dir -type f -printf "%T@ %Tc %p\n" 2>/dev/null |
        sort -n |
        tail -n1 |
        cut -d" " -f9)
}
# get last modified file:1 ends here

# main
# https://www.baeldung.com/linux/check-if-file-write-in-progress


# [[file:docs/auto_pipeline_runner.org::*main][main:1]]
main () {
    before_last_modified_file=$(get_last_modified_file)
    before_bytes=$(stat -c%s "$before_last_modified_file")
    sleep $interval
    after_last_modified_file=$(get_last_modified_file)
    after_bytes=$(stat -c%s "$after_last_modified_file")
    echo "$before_last_modified_file $before_bytes $after_last_modified_file $after_bytes"
    if [ "$before_last_modified_file" = "$after_last_modified_file" ]; then
        if [ $before_bytes -eq $after_bytes ]; then
            echo "True";
        else
            echo "False";
        fi
    else
        echo "False";
    fi
}
main "$@"
# main:1 ends here
