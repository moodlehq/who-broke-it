who-broke-it
============

Finds which commit is breaking "something", where something can be a test suite, script...

Copied from who-broke-it.sh documentation block:

     Checks that the current branch doesn't contain regressions.

     Runs the provided script and, if it fails, gets the failed test and
     runs git bisect from HEAD to the latest known good revision until
     it finds which commit is introducing the regression.

     This script make use of subscripts to know if a revision is "good"
     or "bad" and to determine what is failing.

     Info about how to write these scripts:
     - By default they should not return any exit code, but they can
       fail (and in fact should fail) if there is any internal problem.
     - Git bisect expects an error exit code between 1 and 127, this script
       calls the sub-script with a single argument with value 1, so
       when the sub-script is failing (exit != 0) they should include a:
         if [ "$1" == "1" ]; then
             exit 1
         fi

     Usage:
       cd /current/working/directory
       ./who-broke-it.sh ./SCRIPTNAME LASTGOODHASH [FAILEDSCENARIO] [SUITE]

     Arguments:
       $1 => The name of the script that we are testing against the codebase
       $2 => The last good revision we know of, usually latest weekly.
       $3 => (optional) Failed feature relative path.
       $4 => (optional) Behat suite to execute.


Installation & Usage
====================

* Link the *.sh scripts to your moodle codebase.

```
ln -s /path/to/who-broke-it/who-broke-it.sh /path/to/your/moodle/site
ln -s /path/to/who-broke-it/script-file-name.sh /path/to/your/moodle/site
ln -s .....
```
* Ensure that you set properly whatever is required in config.php to run

```
$CFG->phpunit_prefix = 'p_';
$CFG->phpunit_dataroot = '/path/to/phpunit/dataroot';
$CFG->behat_prefix = 'x_';
$CFG->behat_dataroot = '/path/to/behat/dataroot';
$CFG->behat_wwwroot = 'http://yourip/your/site/path';
```
* Ensure HEAD is pointing where you want
* Run it

```
./who-broke-it.sh ./SCRIPT_NAME.sh LAST_GOOD_KNOWN_GIT_HASH [FAILEDSCENARIO] [SUITE]
```
