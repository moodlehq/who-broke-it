#!/bin/bash

##
# Checks that the current branch doesn't contain regressions.
#
# Runs the provided script and, if it fails, gets the failed test and
# runs git bisect from HEAD to the latest known good revision until
# it finds which commit is introducing the regression.
#
# This script make use of subscripts to know if a revision is "good"
# or "bad" and to determine what is failing.
#
# Info about how to write these scripts:
# - By default they should not return any exit code, but they can
#   fail (and in fact should fail) if there is any internal problem.
# - Git bisect expects an error exit code between 1 and 127, this script
#   calls the sub-script with a single argument with value 1, so
#   they should include a:
#     if [ "$1" == "1" ]; then
#         exit 1
#     fi
#
# Usage:
#   cd /current/working/directory
#   ./who-broke-it.sh ./SCRIPTNAME LASTGOODHASH [FAILEDSCENARIO] [SUITE]
#
# Arguments:
#   $1 => The name of the script that we are testing against the codebase
#   $2 => The last good revision we know of, usually latest weekly.
#   $3 => (optional) Failed feature relative path.
#   $4 => (optional) Behat suite to execute.
##

set -e

# Hardcoded strings.
usageinfo="Usage ./who-broke-it.sh ./SCRIPTNAME LASTGOODHASH [FAILEDSCENARIO] [SUITE]"

if [ -z $1 ]; then
    echo "Error: $usageinfo"
    exit 1
fi
if [ -z $2 ]; then
    echo "Error: $usageinfo"
    exit 1
fi

if [ -n "$failedscenario" ]; then
    echo "Checking who broke $failedscenario"
elif [[ -z $3 ]]; then
    echo "Going to find the failed now."
else
    ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    export failedscenario=${ROOT_DIR}/$3
    export failedtest=${ROOT_DIR}/$3
    echo "Checking who broke $failedscenario"
fi

if [[ -n $4 ]]; then
    export suite=$4
fi

if [ ! -f $1 ]; then
    echo "Error: $1 does not exist"
    exit 1
fi

# Run the tests.
. $1
if [ $failed -eq 0 ]; then
    echo "No failures found in head. Please check branch."
    exit 0
else
    echo "Checking who broke my test..."
fi

# If they fail we bisect until we find where they fail.
git bisect start HEAD $2

git bisect run $1 1
echo "YOU CAN SEE WHO BROKE IT IN THE COMMIT ABOVE"

# Return to the original HEAD.
git bisect reset
