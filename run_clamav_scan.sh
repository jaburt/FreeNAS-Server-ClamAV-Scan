#!/bin/sh

### Execute a shell script on the ClamAV jail, which updates the Anti-Virus definitions and then runs a scan ###
## Hash out the relevant lines depending on whether you are using warden or iocage for Jails
## warden = FreeNAS v11.1 and below
## iocage = FreeNAS v11.1 and above (yes FreeNAS v11.1 supports both warden and iocage!)

## Define the location where the "avscan.sh" shell script is located within the jail:
scriptLocation="/mnt/Sysadmin/scripts/"

## define the name of the Jails
clamAVJailName="ClamAV"

## Execute the script ##
# hash out the one you ware using: jexec = warden, iocage exec = iocage
#jexec "${clamAVJailName}" "$scriptLocation"avscan.sh
iocage exec "${clamAVJailName}" "${scriptLocation}"avscan.sh

## email the log ##
# hash out the one you ware using: /mnt/tank = warden, /mnt/iocage exec = iocage 
#sendmail -t < /mnt/tank/Jails/${clamAVJailName}/tmp/clamavemail.tmp
sendmail -t < /mnt/iocage/jails/${clamAVJailName}/root/tmp/clamavemail.tmp

## Delete the log file ##
# hash out the one you ware using: /mnt/tank = warden, /mnt/iocage exec = iocage
#rm /mnt/tank/Jails/${clamAVJailName}/tmp/clamavemail.tmp
rm /mnt/iocage/jails/${clamAVJailName}/root/tmp/clamavemail.tmp
