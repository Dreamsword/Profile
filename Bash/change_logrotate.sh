#!/bin/bash

clear

read -r -sp "Enter Your Password: " "passvar"

cert="/path/to/.ssh/id_rsa"

servers=("server1.example.com" "server2.example.com" "server3.example.com")

for f in "${servers[@]}"
do
echo ""
echo "$f"
echo ""
ssh -i $cert username@"$f" "echo $passvar | sudo -S sed -i 's/10/365/g' /etc/logrotate.d/exim4-base" 2> /dev/null
done