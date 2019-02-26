#!/bin/bash
# Backup a Plex database.
# Plex Location. 
plexLocation="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/"

# Location to backup the directory to.
backupDirectory="/media/cloud/Plex Backup/Plex/" # Easily be done as root with a cron job
password="<your password here>"

# Set The Date.
DateNow=$(date +"%F" -d "now")

# Stop Plex
echo $password | sudo -S service plexmediaserver stop 2>&1

# Backup Plex
echo $password | sudo -S tar --exclude='/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Cache' -zcvf /tmp/backup_$Datenow.tgz $plexLocation 2>&1

# Restart Plex
echo $password | sudo -S service plexmediaserver start 2>&1

# Move file to backup location 
mv /tmp/backup_$Datenow.tgz $backupDirectory

# Done