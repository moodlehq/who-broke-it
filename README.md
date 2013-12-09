who-broke-it
============

Finds which commit is breaking "something", where something can be a test suite, script...

Copied from who-broke-it.sh documentation block:

 Checks that the current branch doesn't contain regressions.

 Runs the provided script and, if it fails, runs git bisect from
 HEAD to the latest known good revision until it finds which
 commit is introducing a regression.

 This script make use of subscripts to know if a revision is "good"
 or "bad". Info about how to write these scripts:
 - By default they should not return any exit code, but they can
   fail (and in fact should fail) if there is any internal problem.
 - Git bisect expects an exit code, this script calls the sub-script
   with a single argument with value 1, so they should include a:
     if [ ! -z $1 ]; then
         exit $subscriptexitcode
     fi

 Usage:
  cd /current/working/directory
   ./who-broke-it.sh SCRIPTNAME LASTGOODHASH

 Arguments:
   $1 => The name of the script that we are testing against the codebase
   $2 => The last good revision we know of, usually latest weekly.


Installation & Usage
====================

# Copy the *.sh scripts to your moodle codebase.
# Ensure that you set properly whatever is required in config.php to run
  the script you want to run.
# Ensure HEAD is pointing where you want
# Run who-broke-it.sh SCRIPT_NAME.sh LAST_GOOD_KNOWN_GIT_HASH
