#!/bin/bash

### Notes ###
# This script will perform a scan of files in the target location, using ClamAV.
# The "target location" is passed as a parameter to the "run_clamav_scan.sh" script,
# i.e. run_clamav_scan.sh "/mnt"
#
# If you do not pass a parameter or the parameter passed doesn't exists as a file
# or directory, the script will email you an invalid parameter alert.
#
# Once the parameter has been checked and passed, this script will perform a scan
# of the target location.  Please note, that depending on the amount of files to
# scan this task could take a while (i.e. hours/days).
#
# The latest version of this script can be found at:
#	https://www.github.com/jaburt
#
# A discussion forum for this script can be found at:
# 	https://www.ixsystems.com/community/threads/how-to-install-clamav-on-freenas-v11.56790/
#
# This script has been checked for bugs with the online ShellCheck website:
#	https://www.shellcheck.net/
#
# https://www.clamav.net/
# ClamAV® is an open source (GPL) anti-virus engine used in a variety of situations
# including email scanning, web scanning, and end point security. It provides a number
# of utilities including a flexible and scalable multi-threaded daemon, a command line
# scanner and an advanced tool for automatic database updates.
### End ###

### Updates ###
# 17 March 2020: Updated "run_clamav_scan.sh" as FreeNAS v11.3 has moved iocage to
# "/mnt/tank/iocage" from "/mnt/iocage", which was the location if you manually created
# iocage jails in v11.1 before using the UI in v11.2.
#
# 17 March 2020: Have hashed out the [echo "Content-Type: text/html"] lines as there
# is an issue with FreeNAS v11.3 and sendmail.  With these line(s) enabled the email
# will not be sent, but if you hash (#) it out they are sent! For now I have just hashed
# it out, so the email works - will re enable once the issue is fixed in FreeNAS v11.3-U2:
# (https://jira.ixsystems.com/browse/NAS-105003).
#
# 24 March 2020: A complete rewrite to improve and fix some minor issues.
# Have updated it as follows:
#	* reduced coding and scripts to now only require a single script to run;
#	* turned all hard-coded log file names into variables;
#	* added in complete setup and usage instructions;
# 	* defining 'root' as the default email (so no need to edit this if happy
#	  with that);
#	* script now requires a parameter of the target location to scan (with error
#	  checking);
# 	* simplified the editing requirements for the endusers who are running in
#	  warden jails instead of iocage;
#	* the script now supports concurrent runs, by using automatically generated
#	  unique files names for the log files.
#	* separated and automated the freshclam update independently from this script,
#	  so you can configure how often you want to update the virus definitions.
### End ###

### Usage ###
# To use this script you need to follow the instructions as below, examples are done
# using iocage commands (just swap to jexec commands if still using warden jails):
#
# 1) Creating Jail
#	 Create a new Jail, I recommend its called "ClamAV".  Don't forget to configure
#	 it to auto start on server reboots.  Once created you need to start the Jail:
#
#	 iocage start ClamAV
#
# 2) Installing ClamAV (this will take a while)
#	 You now need to update the Jail and and install ClamAV (using "ports"), once
# 	 finished you can then "exit" the Jail and restart it.  I also recommend you
#	 install "portmaster" which will make managing updates easier - see (6).
#
#	 iocage console ClamAV
#	 pkg update && pkg upgrade -y
#	 portsnap fetch
#	 portsnap extract
#	 cd /usr/ports/ports-mgmt/portmaster
#	 make install clean
#	 cd /usr/ports/security/clamav
#	 make install clean
#	 exit
#	 iocage restart -s ClamAV
#
# 3) Configure freshclam (this updates the virus definition files)
#	 You can now configure freshclam, freshclam needs to be configured to run as
#	 a daemon (i.e. always running within the Jail), to automate definition updates,
#	 based on the amount of updates you want to do each day (default is 12 updates/day).
#
#	 iocage console ClamAV
#	 freshclam
# 	 touch /var/log/clamav/freshclam.log
# 	 chmod 600 /var/log/clamav/freshclam.log
# 	 chown clamav /var/log/clamav/freshclam.log
#
#	 You now need to edit the "freshclam.conf" file, which should be found at
#	 "/usr/local/etc/freshclam.conf".  You will want to edit/check the following
#	 options:
#
#	 Location of freshclam.log file:
#		UpdateLogFile /var/log/clamav/freshclam.log
#	 Number of checks (for updates) per day (default is 12):
#		Checks amount
#
#	 You now need to start freshclam as a daemon service, and then exit and stop
#	 the Jail by typing the following commands (this only needs to be done once):
#
#	 sysrc clamav_freshclam_enable="YES"
#	 freshclam -d
#	 exit
#	 iocage stop ClamAV
#
# 4) Add the shares (i.e. datasets) you wish to scan by using the Jails -> Mount Points
#	 feature (I recommend Read-Only mounts).  Remember, if the files/directories are not
#	 mounted then you will not be able to scan them with this script.
#
#	 I recommend you mount them into the /mnt directory and use the same naming scheme
#	 as your datasets (makes it easier to remember), for example:
#
#	 (FreeNAS server)								(ClamAV Jail)
#	 /mnt/tank/Sysadmin		---> mounted to ---->	/mnt/tank/Sysadmin
#	 /mnt/tank/Documents	---> mounted to ---->	/mnt/tank/Documents
#
#	 Once you have configured your mounts you will need to start the Jail again:
#
#	 iocage start ClamAV
#
# 5) Setup a Tasks -> Cron Jobs on the FreeNAS server to run this script with the
#	 scan location as a parameter,  i.e. run_clamav_scan.sh "scan target".  This
# 	 script does some error checking and then runs the scan - an email will be sent
#	 upon completion.  You can configure multiple scans with different scan locations
#	 and start times based on your needs.  The script can now be run concurrently as
#	 many times as you need!
#
# 6) Updating ClamAV
#	 Over time new versions of ClamAV will be released and you will want to upgrade
#	 to them. You will see a notification that ClamAV is out-of-date in the email
#	 you receive via this script.  Therefore to update the ClamAV installation, you
#	 need to do the following:
#
#	 iocage console ClamAV
#	 portsnap fetch
#	 portsnap update
#	 portmaster -a
#	 exit
#	 iocage restart -s ClamAV
#
#	 The command "portmaster -a" will update all outdated ports within the Jail. If
#	 you wish to see which ports would be updated then you can use the command
#	 "portmaster -L."
### End ###

### User Defined Variables ###
# Hash out (#) the relevant lines depending on whether you are using warden or iocage
# for Jails, if your jails are not in the default location, please update the path
# in the "jail_location" variable:
#
# 	warden = FreeNAS v11.1 and below
# 	iocage = FreeNAS v11.1 and above (yes FreeNAS v11.1 supports both warden and iocage!)

#jail_type="warden"
#jail_location="/mnt/tank/Jails/"
jail_type="iocage"
jail_location="/mnt/tank/iocage/jails/"

## Define the name of the Jail where ClamAV is installed
clamAVJailName="ClamAVAV"

# Your email address, so that you can receive the emails generated by this script.
# This defaults to 'root' and thus the email address you have defined for root, if
# you want a different email, please edit appropriately.
your_email=root
### End ###

#################################################################
##### THERE IS NO NEED TO EDIT ANYTHING BEYOUND THIS POIINT #####
#################################################################

### System/Script defined Variables ###
# To allow concurrent runs of this script, the log files need to have unique names,
# a way to do this is by using the Process ID (PID) of this script as it runs.
# This is found by using the special code $$.
pid=$$

# Location and name of the log/temp files used by the script, all but the freshclam.log
# file are automatically deleted at the end of the script.  Adding the Process ID makes
# them unique for concurrent runs.
invalid_email_body=/tmp/jab_clamav_invalid$pid.txt
valid_email_body=/tmp/jab_clamav_valid$pid.txt
clamscan_log=/var/log/clamav/jab_clamscan$pid.log
freshclam_log=/var/log/clamav/freshclam.log

# Create a variable with the start date/time of script execution.
started=$(date "+run_clamav_scan.sh script started at: %Y-%m-%d %H:%M:%S")

# Allocate the parameter passed to a internal script variable, and calculate the
# absolute path to the scan location from FreeNAS root (for file/directory
# verification).  As well as generate full paths to the log files (to reduce amount
# of "if" statements needed.
scan_location=$1

if [ $jail_type = "iocage" ]; then
	scan_location_absolute=${jail_location}${clamAVJailName}/root${scan_location}
	freshclam_log_fullpath=${jail_location}${clamAVJailName}/root${freshclam_log}
	clamscan_log_fullpath=${jail_location}${clamAVJailName}/root${clamscan_log}
else
	scan_location_absolute=${jail_location}${clamAVJailName}${scan_location}
	freshclam_log_fullpath=${jail_location}${clamAVJailName}${freshclam_log}
	clamscan_log_fullpath=${jail_location}${clamAVJailName}${clamscan_log}
fi
### End ###

### A short function to tidy-up after the script has finished.
run_tidyup()
{
# Delete all the log and temp files which are no longer needed, in preparation
# for a new set of files on the next run as well as to save space!
rm -f "${invalid_email_body}"
rm -f "${valid_email_body}"
rm -f "${clamscan_log_fullpath}"
}
### End ###

### A function to report that an invalid parameter has been passed upon script execution.
run_invalid()
{
# Define the email text.
(
    echo "To: ${your_email}"
    echo "Subject: ClamAV Scan - ERROR: ${1}"
    echo "MIME-Version: 1.0"
#    echo "Content-Type: text/html"
    echo -e "\\r\\n"
	echo "${started}$(date "+ and finished at: %Y-%m-%d %H:%M:%S")"
	echo ""
	echo "To start a ClamAV scan, you need to pass the location of a valid directory or file, i.e."
	echo ""
	echo '		 run_clamav_scan.sh "/mnt/tank"'
	echo ""
	echo 'Remember: Placing the scan location in "quotes" allows you to scan files/directories which may have spaces in their name.'
	echo "Also, the directory or file you wish to scan needs to be mounted (read-only is recommended) within the ClamAV Jail."
	echo ""
	echo "------------------------------------------------------------------------------------------------------------------------------"
	echo "Please Note: The latest version of this script can be found at: https://www.github.com/jaburt"
	echo "------------------------------------------------------------------------------------------------------------------------------"
) > "${invalid_email_body}"

# Send the email
sendmail -t < ${invalid_email_body}
}
### End ###

### The function which calls and executes the ClamAV scan.
run_clamav()
{
# Execute the script and log the results. The parameters used with clamscan are:
#
# Only print infected files: -i
# Scan subdirectories recursively: -r
# Continue scanning within file after finding a match: -z
# Show filenames inside scanned archives: -a
# Save scan report to FILE: -l ${clamscan_log}

if [ $jail_type = "iocage" ] ; then
	iocage exec "${clamAVJailName}" clamscan -i -r -z -a -l ${clamscan_log} "${scan_location}"
else
	jexec "${clamAVJailName}" clamscan -i -r -l ${clamscan_log} "${scan_location}"
fi
}
### End ###

### The function which formats the log and emails it.
run_sendscanresults()
{
# Define the email text.
(
    echo "To: ${your_email}"
    echo "Subject: ClamAV Scan - SUCCESS: ${scan_location}"
    echo "MIME-Version: 1.0"
#    echo "Content-Type: text/html"
    echo -e "\\r\\n"
	echo "${started}$(date "+ and finished at: %Y-%m-%d %H:%M:%S")"
    echo ""
    echo "--------------------------------------"
    echo "ClamAV Scan Summary"
    echo "--------------------------------------"
	tail -n 8 "${clamscan_log_fullpath}"
    echo ""
    echo ""
    echo "--------------------------------------"
    echo "freshclam log file"
    echo "--------------------------------------"
	tail -r "${freshclam_log_fullpath}" | tail -n +2 | sed '/--------------------------------------/q' | sed '$d' | tail -r
    echo ""
    echo ""
    echo "--------------------------------------"
    echo "List of suspicious files found"
	echo "--------------------------------------"
	tail -n +4 "${clamscan_log_fullpath}" | sed -e :a -e '$d;N;2,10ba' -e 'P;D'
	echo ""
	echo "------------------------------------------------------------------------------------------------------------------------------"
	echo "Please Note: The latest version of this script can be found at: https://www.github.com/jaburt"
	echo "------------------------------------------------------------------------------------------------------------------------------"
) >> ${valid_email_body}

# Send the email
sendmail -t < ${valid_email_body}
}
### End ###

### Check for a valid scan target and branch appropriately ###
# If no parameter was passed, exit with invalid parameter email.
if [ $# -eq 0 ]; then
	run_invalid "No Parameter Provided!"
	run_tidyup
    exit 1
fi

# Now check that the file/directory passed as a parameter is valid
if [ -d "${scan_location_absolute}" ] ; then
	run_clamav "${scan_location}"
	run_sendscanresults
	run_tidyup
	exit 0
elif [ -f "${scan_location_absolute}" ] ; then
	run_clamav "${scan_location}"
	run_sendscanresults
	run_tidyup
	exit 0
else
	run_invalid "Scan Target Location Does Not Exist! ${scan_location}"
	run_tidyup
	exit 1
fi
### End ###
