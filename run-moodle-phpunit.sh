#!/bin/bash

##
# Simple script to run CWD site phpunit tests.
#
# It will be called by who-broke-it.sh.
#
# Info:
#   - Moodle's dirroot contains the codebase and a config.php with:
#     * $CFG->phpunit_dataroot
#     * $CFG->phpunit_prefix
#
# Arguments:
#   $1 => When called through git bisect (== 1) whether we should return an
#   exit code after finishing.
#
# Failed test:
#   testcase filepath (e.g. core_demo_testcase lib/tests/demo_test.php)
##

set -e

returnexitcode=$1

# Hardcoded vars.
phpunitcommand='vendor/bin/phpunit'

# Get composer.phar and install dependencies if they are not there.
if [ -f "composer.phar" ]; then
    php composer.phar self-update > /dev/null
else
    curl -sS https://getcomposer.org/installer | php > /dev/null
    php composer.phar update --dev > /dev/null
fi

# Upgrade phpunit site.
echo "** Upgrading test site... **"
if ! $( php admin/tool/phpunit/cli/init.php > /dev/null ); then
    echo "Error: Test site can not be upgraded"
    exit 1
fi

# Run phpunit stopping on failures. We want to detect the first failure and
# continue running against the next revision.
phpunitfullcommand="$phpunitcommand --stop-on-failure"

# If there is already a failed test we only run that one.
if [ "$failedtest" != "" ]; then
    phpunitfullcommand="$phpunitfullcommand $failedtest"
else
    phpunitfullcommand="$phpunitfullcommand mod/lesson/tests/lib_test.php"
fi

echo "** Running $phpunitfullcommand **"
if ! phpunitoutput=$( ${phpunitfullcommand} ); then

    # Flag the test as failed.
    failed=1

    # Get the proposed re-run test which contains the failed file
    line=$( echo "$phpunitoutput" | grep "vendor/bin/phpunit" | sed 's/^ *//g' )
    export failedtest=$( echo "$line" | awk '{print $2,$3}' )
    echo "** Failed test: $failedtest **"
fi

# Using == "1" instead of just a '! -z' as $1 can also be who-broke-it.sh
# first argument.
if [ "$returnexitcode" == "1" ]; then

    if [ "$failed" == "1" ]; then
        # Returning generic error exit code as git bisect only accepts codes
        # between 1 and 127 (excluding 125) so we need to control script's return.
        exit 1
    else
        exit 0
    fi
fi
