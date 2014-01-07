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
#   $1 => Whether we should return an exit code after finishing.
##

set -e

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
echo "UPGRADING TEST SITE..."
php admin/tool/phpunit/cli/init.php > /dev/null

# Run phpunit stopping on failures, we want to detect the first one and run again against the next revision.
# We set $failed because we need to continue in who-broke-it.sh until we find the issue.
phpunitfullcommand="$phpunitcommand --stop-on-failure"

# If there is already a failed test we only run that one.
if [ "$failedtest" != "" ]; then
    phpunitfullcommand="$phpunitfullcommand $failedtest"
fi

echo "RUNNING $phpunitfullcommand"
if ! phpunitoutput=$( ${phpunitfullcommand} ); then

    failed=1

    # Get the proposed re-run test which contains the failed file
    line=$( echo "$phpunitoutput" | grep "vendor/bin/phpunit" | sed 's/^ *//g' )
    export failedtest=$( echo "$line" | awk '{print $2,$3}' )
    echo "FAILED TEST: $failedtest"

fi

# Exit returning behat's error code as bisect run needs it.
if [ "$1" == "1" ]; then
    # Returning generic error exit code as git bisect only accepts codes
    # between 1 and 127 (excluding 125) so we need to control script's return.
    exit 1
fi
