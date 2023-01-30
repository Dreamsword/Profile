#!/bin/bash

clear

read -r -sp "Enter Your Password: " "passvar"

cert="/Users/Dreamsword/.ssh/id_rsa"
FILE="/home/hein/New_Certs"
BACKUP="/home/hein/Backup_Certs"
ssl="/etc/ssl"
exim="/etc/exim4"

servers=("some.url.com")

for f in "${servers[@]}"
do
ssh -i $cert hein@"$f" "mkdir Backup_Certs" 2> /dev/null
ssh -i $cert hein@"$f" "echo $passvar | sudo -S cp $ssl/* $BACKUP && echo $passvar | sudo -S cp $FILE/gd_intermediate.crt $ssl/ &&  echo $passvar | sudo -S cp $FILE/_.rocketseed.com.* $ssl/ && echo $passvar | sudo -S cp $FILE/tls_ssl_certs" 2> /dev/null
echo ""
echo "$f Done"
done