#!/bin/sh

### Notes ###
## Shell scripts to update the ClamAV definitions, then run a scan and prepare an email template
## This script is called from a master script running as a cron job on the FreeNAS server
## Master script is: run_clamav_scan.sh
##
## Instructions:
## 1) To use this you need to create a Jail, I recommend "ClamAV"
## 2) Install ClamAV using "ports"
## 3) You can then "exit" the Jail
## 4) Add the windows shares you wish to scan by using the Jail Add Storage feature
## 5) Add the shares to same location you use in the variable: "scriptLocation"
## 6) Setup a cronjob on the FreeNAS server to run a shell script on the FreeNAS server: "run_clamav_scan.sh"
## 7) The shell script "run_clamav_scan.sh" then connects to the Jail and runs this script.
## 8) Once finished, the "run_clamav_scan.sh" script emails a log to the email entered in the variable: "toEmail"
##
## https://www.clamav.net/
## ClamAV® is an open source (GPL) anti-virus engine used in a variety of situations including email scanning, web scanning,
## and end point security. It provides a number of utilities including a flexible and scalable multi-threaded daemon, a command
## line scanner and an advanced tool for automatic database updates.

### Parameters ###
## email address
toEmail="your@email.address"

## Top directory of the files/directories you wish to scan, i.e. the "Jail Add Storage" locations
scriptLocation="/mnt"
### End ###

### Update anti-virus definations ###
freshclam -l /var/log/clamav/freshclam.log
### End ###

### Run the anti-virus scan ###
started=$(date "+ClamAV Scan started at: %Y-%m-%d %H:%M:%S")
clamscan -i -r -l /var/log/clamav/clamscan.log "${scriptLocation}"
finished=$(date "+ClamAV Scan finished at: %Y-%m-%d %H:%M:%S")
### End ###

### prepare the email ###
## Set email headers
(
    echo "To: ${toEmail}"
    echo "Subject: ${started}"
    echo "MIME-Version: 1.0"
    echo "Content-Type: text/html"
    echo -e "\\r\\n"
) > /tmp/clamavemail.tmp

## Set email body
(
    echo "<pre style=\"font-size:14px\">"
    echo "${started}"
    echo ""
    echo "${finished}"
    echo ""
    echo "--------------------------------------"	
    echo "ClamAV Scan Summary"
    echo "--------------------------------------"
    tail -n 8 /var/log/clamav/clamscan.log
    echo ""
    echo ""	
    echo "--------------------------------------"
    echo "freshclam log file"
    echo "--------------------------------------"
    tail -n +2 /var/log/clamav/freshclam.log
    echo ""
    echo ""    
    echo "--------------------------------------"
    echo "clamav log file"
    echo "--------------------------------------"
    tail -n +4 /var/log/clamav/clamscan.log | sed -e :a -e '$d;N;2,10ba' -e 'P;D'
    echo "</pre>"
) >> /tmp/clamavemail.tmp

### Tidy Up ###
## Delete the freshclam log in preparation of a new log
rm /var/log/clamav/freshclam.log

## Delete the clamscan log in preparation of a new log
rm /var/log/clamav/clamscan.log
### End ###
