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
phpunitcommand='vendor/bin/phpunit --stop-on-failure'

# Get composer.phar and install dependencies if they are not there.
if [ -f "composer.phar" ]; then
    php composer.phar self-update > /dev/null
else
    curl -sS https://getcomposer.org/installer | php > /dev/null
    php composer.phar update --dev > /dev/null
fi

# Upgrade phpunit site.
php admin/tool/phpunit/cli/init.php > /dev/null

# Run phpunit stopping on failures, we want to detect the first one and run again against the next revision.
# We set $failed because we need to continue in who-broke-it.sh until we find the issue.
echo $phpunitcommand
exitcode=0
if ${phpunitcommand}; then
    exitcode=$?
    failed=1
fi

# Exit returning behat's error code as bisect run needs it.
if [ "$1" == "1" ]; then
    exit $exitcode
fi
