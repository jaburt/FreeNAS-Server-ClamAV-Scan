## Description
This script will perform a scan of files in the target location, using ClamAV.
The "target location" is passed as a parameter to the `run_clamav_scan.sh` script,
i.e. `run_clamav_scan.sh "/mnt"`

If you do not pass a parameter or the parameter passed doesn't exists as a file
or directory, the script will email you an invalid parameter alert.

Once the parameter has been checked and passed, this script will perform a scan
of the target location.  Please note, that depending on the amount of files to
scan this task could take a while (i.e. hours/days).

The latest version of this script can be found at:
	https://www.github.com/jaburt

A discussion forum for this script can be found at:
	https://www.ixsystems.com/community/threads/how-to-install-clamav-on-freenas-v11.56790/

This script has been checked for bugs with the online ShellCheck website:
https://www.shellcheck.net/

ClamAV® is an open source (GPL) anti-virus engine used in a variety of situations
including email scanning, web scanning, and end point security. It provides a number
of utilities including a flexible and scalable multi-threaded daemon, a command line
scanner and an advanced tool for automatic database updates:
https://www.clamav.net/

## Updates
17 March 2020: Updated `run_clamav_scan.sh` as FreeNAS v11.3 has moved iocage to
`/mnt/tank/iocage` from `/mnt/iocage`, which was the location if you manually created
iocage jails in v11.1 before using the UI in v11.2.

17 March 2020: Have hashed out the `echo "Content-Type: text/html"` lines as there
is an issue with FreeNAS v11.3 and sendmail.  With these line(s) enabled the email
will not be sent, but if you hash (#) it out they are sent! For now I have just hashed
it out, so the email works - will re enable once the issue is fixed in FreeNAS v11.3-U2:
(https://jira.ixsystems.com/browse/NAS-105003).

24 March 2020: A complete rewrite to improve and fix some minor issues.
Have updated it as follows:

* reduced coding and scripts to now only require a single script to run;
* turned all hard-coded log file names into variables;
* added in complete setup and usage instructions;
* defining 'root' as the default email (so no need to edit this if happy with that);
* script now requires a parameter of the target location to scan (with error checking);
* simplified the editing requirements for the endusers who are running in warden jails instead of iocage;
* the script now supports concurrent runs, by using automatically generated unique files names for the log files.
* separated and automated the freshclam update independently from this script, so you can configure how often you want to update the virus definitions.

02 April 2020: Notice a small mistake on the "sendmail" command, it didn't have the -oi parameter.

## Usage
To use this script you need to follow the instructions as below, examples are done
using iocage commands (just swap to jexec commands if still using warden jails):

1) Editing the script

There are four user-defined fields within the script.  If you are using iocage, and are happy for the email to go to root and using the jail name ClamAV; then there is no need to edit any of them.  Otherwise edit as per the notes in that section of the script.

2) Creating A Jail

Create a new Jail, I recommend its called `ClamAV`.  Don't forget to configure it to auto start on server reboots.  Once created you need to start the Jail:
```
	iocage start ClamAV
```
3) Installing ClamAV (this will take a while)

You now need to update the Jail and and install ClamAV (using `ports`), once finished you can then `exit` the Jail and restart it.  I also recommend you install `portmaster` which will make managing updates easier - see (6):
```
	iocage console ClamAV
	pkg update && pkg upgrade -y
	portsnap fetch
	portsnap extract
	cd /usr/ports/ports-mgmt/portmaster
	make install clean
	cd /usr/ports/security/clamav
	make install clean
	exit
	iocage restart -s ClamAV
```
4) Configure freshclam (this updates the virus definition files)

You can now configure freshclam, freshclam needs to be configured to run as a daemon (i.e. always running within the Jail), to automate definition updates, based on the amount of updates you want to do each day (default is 12 updates/day):
```
 	iocage console ClamAV
 	freshclam
	touch /var/log/clamav/freshclam.log
	chmod 600 /var/log/clamav/freshclam.log
	chown clamav /var/log/clamav/freshclam.log
```
You now need to edit the `freshclam.conf` file, which should be found at `/usr/local/etc/freshclam.conf`.  You will want to edit/check the following options:
```
	Location of freshclam.log file:
 		UpdateLogFile /var/log/clamav/freshclam.log
	Number of checks (for updates) per day (default is 12):
		Checks amount
```
You now need to start freshclam as a daemon service, and then exit and stop the Jail by typing the following commands (this only needs to be done once):
```
	sysrc clamav_freshclam_enable="YES"
	freshclam -d
	exit
	iocage stop ClamAV
```
5) Add the shares (i.e. datasets) you wish to scan

Using the Jails -> Mount Points feature (I recommend Read-Only mounts).  Remember, if the files/directories are not mounted then you will not be able to scan them with this script.

I recommend you mount them into the /mnt directory and use the same naming scheme as your datasets (makes it easier to remember), for example:
```
 	(FreeNAS server)				(ClamAV Jail)
 	/mnt/tank/Sysadmin	---> mounted to ---->	/mnt/tank/Sysadmin
 	/mnt/tank/Documents	---> mounted to ---->	/mnt/tank/Documents
```
Once you have configured your mounts you will need to start the Jail again:
```
	iocage start ClamAV
```
6) Setup a Tasks -> Cron Jobs on the FreeNAS server

Run this script with the scan location as a parameter,  i.e. `run_clamav_scan.sh "scan target"`.  This script does some error checking and then runs the scan - an email will be sent upon completion.  You can configure multiple scans with different scan locations and start times based on your needs.  The script can now be run concurrently as many times as you need!

7) Updating ClamAV

Over time new versions of ClamAV will be released and you will want to upgrade to them. You will see a notification that ClamAV is out-of-date in the email you receive via this script.  Therefore to update the ClamAV installation, you need to do the following:
```
	iocage console ClamAV
	portsnap fetch
	portsnap update
	portmaster -a
	exit
	iocage restart -s ClamAV
```
 The command `portmaster -a` will update all outdated ports within the Jail. If you wish to see which ports would be updated then you can use the command `portmaster -L`.
