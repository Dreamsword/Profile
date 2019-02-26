#!/bin/bash

# Push backups to an Offsite FTP Server - Offsite backups
# Ensure that ncftp packages are installed, or install them as below
# apt-get install ncftp
# Send OK / Failure directly to Zabbix

# Define Variables here
SVR="backup.server.example.com"
PWD="<password>"
USR="<username>"
BKPSRC="/home/bacula/*"
PORT="21"

# Sanity Check Function - Check Completion or Failure
sanity_chk() {
        if [ $1 ==  "ok" ];then
                /usr/bin/zabbix_sender -z <ip here> -s "<server hostname>" -k ftpbackup -o OK
        fi
        if [ $1 == "fail" ];then
                 /usr/bin/zabbix_sender -z <ip here> -s "<server hostname>" -k ftpbackup -o FAILED
        fi
}

data_retention(){
        KEEP=2
        COUNT=$(ncftpls -1 -i '*-backup.tar.gz' -u ${USR} -p ${PWD} ftp://${SVR}| wc -l)
        let EXTRA=$COUNT-$KEEP
        if [ $EXTRA -gt 0 ]; then
                REMOVE=($(ncftpls -1 -i '*-backup.tar.gz' -u ${USR} -p ${PWD} ftp://${SVR} | tail -n$EXTRA))

ftp -vn ${SVR} <<EOFD
 quote USER $USR
 quote PASS $PWD
 binary
 cd /
 delete ${REMOVE[@]}
 quit
EOFD
fi
}
data_retention

ncftpput -d /var/log/ftp_bakup.log -u ${USR} -p ${PWD} -P ${PORT} ${SVR} /  ${BKPSRC}

if [ `echo $?` -eq 0 ];then
        sanity_chk ok;
        else
        sanity_chk fail;
fi