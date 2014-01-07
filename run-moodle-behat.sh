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
#   $1 => Whether we should return an exit code after finishing.
##

set -e

# Hardcoded vars.
behatcommand='vendor/bin/behat'

# Upgrade behat site and update composer dependencies if necessary.
php admin/tool/behat/cli/init.php > /dev/null

# Only to get the command, separated from the former one as we want proper output.
behatrunner=$( php admin/tool/behat/cli/util.php --enable | grep $behatcommand | sed 's/^ *//g' )

# Check that we got the command (means that enable works as expected
# too, so many checks already been done).
if [ -z "$behatrunner" ]; then
    echo "Error: The site should be initialized and ready to test, and it is not."
    exit 1
fi

# Run behat stopping on failures, we want to detect the first one and run again against the next revision.
# We set $failed because we need to continue in who-broke-it.sh until we find the issue.
behatfullcommand="$behatrunner --stop-on-failure"
exitcode=0
echo $behatfullcommand;
if ${behatrunner}; then
    exitcode=$?
    failed=1
fi

# Exit returning behat's error code as bisect run needs it.
if [ "$1" == "1" ]; then
    exit $exitcode
fi
