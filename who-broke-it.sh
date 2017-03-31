#!/bin/bash

##
# Automatic git bisect based on test scripts.
#
# Runs the provided test script in HEAD and, if it fails, automatically bisects
# from the last known good revision using the provided test script until it
# finds the commit that introduced the repository failure.
#
# Usage:
#   cd /current/working/directory
#   ./who-broke-it.sh TESTSCRIPTPATH LASTKNOWNGOOD [FAILEDTEST] [EXTRAARG]
#
# Arguments:
#   $1 => The name of the script that we are testing against the codebase
#   $2 => The last good revision we know of
#   $3 => (optional) Test to run, its value depends on the testing script
#                    but its value is usually a test you know it is failing
#                    so following bisect runs start by the failing test instead
#                    of restarting from the beginning of the test suite.
#   $4 => (optional) An extra argument to make available to the testing script.
#
#
# Info about these test scripts:
#
# - By default they should not return any exit code, but they must
#   fail if there is any internal problem (use set -e).
#
# - $failed var should be set if the test script failed.
#
# - If $1 argument is equals to 1 is because the script has been called from
#   git bisect and it expects an error exit code to be returned. Something like
#   this should be added to the script.
#
#   if [ "$returnexitcode" == "1" ]; then
#
#       if [ "$failed" == "1" ]; then
#           # Returning generic error exit code as git bisect only accepts codes
#           # between 1 and 127 (excluding 125) so we need to control script's
#           # return.
#           exit 1
#       else
#           exit 0
#       fi
#   fi
#
#   The failed test should be filled into $failedtest so the next run
#   will only run the same test instead of starting from the beginning.
#
##

set -e

# Hardcoded strings.
usageinfo="Usage ./who-broke-it.sh TESTSCRIPTPATH GOODREV [FAILEDTEST] \
[EXTRAARG]"

testscript=$1
goodrev=$2
failedtest=$3
extraarg=$4

if [ -z $testscript ]; then
    echo "Error: $usageinfo"
    exit 1
fi
if [ -z $goodrev ]; then
    echo "Error: $usageinfo"
    exit 1
fi

if [ ! -f $testscript ]; then
    echo "Error: $testscript does not exist"
    exit 1
fi
testscript=$(readlink $testscript)
# Absolute path.

if [ -n "$failedtest" ]; then
    # Make failedtest available to test scripts.
    export failedtest=$failedtest
    echo "** Who broke $failedtest ? **"
elif [[ -z $failedtest ]]; then
    echo "** Who broke it? **"
fi

# Forward the extra argument to the executed script.
if [[ -n "$extraarg" ]]; then
    export extraarg="$extraarg"
fi

# Run the tests.
source $testscript
if [ $failed -eq 0 ]; then
    echo "** No failures found in head. **"
    exit 0
else
    echo "** HEAD is broken, checking who broke it... **"
fi

# If they fail we bisect until we find where they fail.
git bisect start HEAD $goodrev

# Execute the script forcing it to return an exit code.
git bisect run $testscript "1"
echo "** The commit above broke it **"

# Return to the original HEAD.
git bisect reset > /dev/null
