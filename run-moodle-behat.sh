#!/bin/bash

##
# Simple script to run CWD site behat tests.
#
# It will be called by who-broke-it.sh.
#
# Info:
#   - Moodle's dirroot contains the codebase and a config.php with:
#     * $CFG->behat_dataroot
#     * $CFG->behat_prefix
#     * $CFG->behat_switchcompletely or $CFG->behat_wwwroot
#   - Selenium or phantomjs is already started.
#
# Arguments:
#   $1 => When called through git bisect (== 1) whether we should return an
#   exit code after finishing.
##

set -e

returnexitcode=$1

# Hardcoded vars.
behatcommand='vendor/bin/behat'

# $extraarg var is the suite in run-moodle-behat context.
suite=$extraarg

# Upgrade behat site and update composer dependencies if necessary.
if [ -n "$suite" ]; then
    echo "** Upgrading test site using suite $suite **"
    if ! $( php admin/tool/behat/cli/init.php -a=$suite > /dev/null ); then
        echo "Error: Test site can not be upgraded"
        exit 1
    fi
else
    echo "** Upgrading test site... **"
    if ! $( php admin/tool/behat/cli/init.php > /dev/null ); then
        echo "Error: Test site can not be upgraded"
        exit 1
    fi
fi

# Only to get the command, separated from the former one as we want proper output.
if [ -n "$suite" ]; then
    behatrunner=$( php admin/tool/behat/cli/util.php --enable -a=$suite | \
        grep $behatcommand | sed 's/^ *//g' )
else
    behatrunner=$( php admin/tool/behat/cli/util.php --enable | \
        grep $behatcommand | sed 's/^ *//g' )
fi

# Check that we got the command (means that enable works as expected
# too, so many checks already been done).
if [ -z "$behatrunner" ]; then
    echo "Error: The site should be initialized and ready to test, it is not."
    exit 1
fi

# Run behat stopping on failures, we want to detect the first one and run
# again against the next revision. We set $failed because we need to continue
# in who-broke-it.sh until we find the issue.
behatfullcommand="$behatrunner --stop-on-failure"

if [ -n "$suite" ]; then
    behatfullcommand="$behatfullcommand --suite=$suite"
fi

# If there is already a failed scenario we only run that one.
if [ "$failedtest" != "" ]; then
    behatfullcommand="$behatfullcommand $failedtest"
fi

echo "** Running $behatfullcommand **"
if ! behatoutput=$( ${behatfullcommand} ); then

    # Flag the test as failed.
    failed=1

    # Get the name of the failed .feature file from the output.
    regex="\# +([^:]*.feature)"
    if [[ $behatoutput =~ $regex ]]; then
        featurefile=${BASH_REMATCH[1]}
    fi

    if [ ! -f "$featurefile" ]; then
        # Can't get the feature file path.
        echo "** Failed feature file could not be extracted from the failure \
output. Next bisect iteration will use the same command that has been used now \
**"
    else
        export failedtest=$featurefile
        echo "** Failed test: $failedtest **"
    fi

fi

# Using == "1" instead of just a '! -z' as $1 can also be who-broke-it.sh
# first argument.
if [ "$returnexitcode" == "1" ]; then

    if [ "$failed" == "1" ]; then
        # Returning generic error exit code as git bisect only accepts codes
        # between 1 and 127 (excluding 125) so we need to control script's
        # return.
        exit 1
    else
        exit 0
    fi
fi
