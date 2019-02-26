#!/bin/bash

##### Universal Functions

read -p "Enter Your Username: " uservar

read -p "Enter Your .ssh location: " key

function pause(){
   read -p "$*"
}

IFS=$'\n' read -d '' -r -a servers < servers.txt

#####

for f in "${servers[@]}"
do
echo ""
if ssh -i $key/.ssh/id_rsa -o BatchMode=yes -o ConnectTimeout=5 $uservar@$f command; [ $? -eq 255 ]
then
  echo $f >> failed.txt
  echo "SSH connection failed" >> failed.txt
  echo "" >> failed.txt
fi
done

#>> checked.txt