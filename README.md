# FreeNAS-Server-ClamAV-Scan

A pair of shell scripts to automate (via a cron job) the anti-virus scan of your FreeNAS shares.

The script will update the ClamAV definitions, then run a scan and prepare an email template.

This script is called from a master script running as a cron job on the FreeNAS server: run_clamav_scan.sh

Instructions:
 1) To use this you need to create a Jail, I recommend "ClamAV"
 2) Install ClamAV using "ports"
 3) You can then "exit" the Jail
 4) Add the windows shares you wish to scan by using the Jail Add Storage feature
 5) Add the shares to same location you use in the variable: "scriptLocation"
 6) Setup a cronjob on the FreeNAS server to run a shell script on the FreeNAS server: "run_clamav_scan.sh"
 7) The shell script "run_clamav_scan.sh" then connects to the Jail and runs this script.
 8) Once finished, the "run_clamav_scan.sh" script emails a log to the email entered in the variable: "toEmail"

If you get the following error message in the freshclam log, you can ignore it. This is because you are not setting up ClamAV as a daemon (i.e. clamd service) in the Jail, and only using it as an on-demand scanner:

WARNING: Clamd was NOT notified: Can't connect to clamd through /var/run/clamav/clamd.sock: No such file or directory

ClamAV® is an open source (GPL) anti-virus engine used in a variety of situations including email scanning, web scanning,
and end point security. It provides a number of utilities including a flexible and scalable multi-threaded daemon, a command
line scanner and an advanced tool for automatic database updates.
https://www.clamav.net/

UPDATES
-------
17 March 2020: Updated run_clamav_scan.sh as FreeNAS v11.3 has moved iocage to /mnt/tank/iocage from /mnt/iocage, which was the location if you manually created iocage jails in v11.1 before using the UI in v11.2.

17 March 2020: Haved hashed out the line : echo "Content-Type: text/html" : in avsacn.sh as there is an issue with FreeNAS v11.3 and sendmail.  With this line enabled the email will not be sent, but if you has (#) it out they are.  For now have just hashed it out, so the email works.
