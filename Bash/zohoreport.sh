#!/bin/bash

rm -rf /tmp/zoho_report.csv
rm -rf /tmp/zoho-tickets.json

curl -s -X GET 'https://desk.zoho.com/api/v1/tickets?receivedInDays=30&status=Closed&from=1&limit=99' -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." > /tmp/zoho-tickets.json
curl -s -X GET 'https://desk.zoho.com/api/v1/tickets?receivedInDays=30&status=Closed&from=100&limit=99' -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." >> /tmp/zoho-tickets.json
curl -s -X GET 'https://desk.zoho.com/api/v1/tickets?receivedInDays=30&status=Closed&from=200&limit=99' -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." >> /tmp/zoho-tickets.json
# curl -s -X GET 'https://desk.zoho.com/api/v1/tickets?receivedInDays=30&status=Open&from=1&limit=99' -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." >> /tmp/zoho-tickets.json
# curl -s -X GET 'https://desk.zoho.com/api/v1/tickets?receivedInDays=30&status=Open&from=100&limit=99' -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." >> /tmp/zoho-tickets.json
# curl -s -X GET 'https://desk.zoho.com/api/v1/tickets?receivedInDays=30&status=Open&from=200&limit=99' -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." >> /tmp/zoho-tickets.json

tickets=$(cat /tmp/zoho-tickets.json | grep 'id\|subject\|status\|createdTime\|closedTime' | grep -v statusType | grep -v email | sed -e 's/"//g; /id:/s/,$//g; /subject:/s/,//g; /status:/s/,$//g; /createdTime:/s/,$//g;' | tr '\n' ' ' | tr -s " " | awk '{$1=$1;print}')

IFS=',' read -a ticketsArray <<< "$tickets"

Tlenght=${#ticketsArray[@]}

echo "Subject,Status,Agents,Created,Closed,Amount" >> zoho_report.csv

for (( i = 0 ; i < $Tlenght ; i++ )) 
do
    id=$(echo ${ticketsArray[$i]} | sed -e 's/ subject:.*//; s/id: //')
    subject=$(echo ${ticketsArray[$i]} | sed -e 's/^id:.*subject: //; s/ status:.*//')
    status=$(echo ${ticketsArray[$i]} | sed -e 's/^id:.*status: //; s/ createdTime:.*//')
    created=$(echo ${ticketsArray[$i]} | sed -e 's/^id:.*createdTime: //; s/ closedTime:.*//; s/Z//g; s/T/ /g')
    closed=$(echo ${ticketsArray[$i]} | sed -e 's/^.*closedTime: //; s/Z//g; s/T/ /g')
    amForm=$(curl -s -X GET "https://desk.zoho.com/api/v1/tickets/$id" -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." | grep "From AM Form" | sed -e 's/"From AM Form"://g; s/"//g' | awk '{$1=$1;print}')

    if [[ $amForm == true ]]; then
        amFormCheck=$(curl -s -X GET "https://desk.zoho.com/api/v1/tickets/$id/threads" -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." | grep "summary" | sed -e 's/"summary"://g; s/"//g' | tail -1 | awk '{$1=$1;print}')
    else
        amFormCheck=""
    fi

    if [[ -n $amFormCheck ]]; then
        vat=$(echo $amFormCheck | grep VAT)
    else
        vat=""
    fi

    if [[ -n $vat ]]; then
        amount=$(echo $amFormCheck | sed -e 's/.*VAT //;s/.Description.*//')
    else
        amount="No Amount Specified"
    fi

    responderIds=$(curl -s -X GET "https://desk.zoho.com/api/v1/tickets/$id/threads" -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." |grep responderId | sed -e 's/"//g; s/responderId: //g; s/ //g; s/$/,/g' | sort | uniq | tr '\n' ' ' | tr -s " " | awk '{$1=$1;print}')
    commenterIds=$(curl -s -X GET "https://desk.zoho.com/api/v1/tickets/$id/comments" -H "orgId:<ID>" -H "Authorization:Zoho-authtoken <TOKEN>" | jq "." |grep commenterId | sed -e 's/"//g; s/commenterId: //g; s/ //g; s/$/,/g' | sort | uniq | tr '\n' ' ' | tr -s " " | awk '{$1=$1;print}')

    IFS=',' read -a responderArray <<< "$responderIds"
    IFS=',' read -a commenterArray <<< "$commenterIds"

    rLenght=${#responderArray[@]}
    cLenght=${#commenterArray[@]}
    for ((r = 0 ; r < $rLenght ; r++))
    do
        if [[ -n ${responderArray[$r]} ]]; then
            rNames=$(cat agents.txt | grep ${responderArray[$r]} | sed -e "s/${responderArray[$r]}//" | awk '{$1=$1;print}')
            agents+=("$rNames;")
        fi
    done
    
    for ((c = 0 ; c < $cLenght ; c++))
    do
        if [[ -n ${commenterArray[$c]} ]]; then
            cNames=$(cat agents.txt | grep ${commenterArray[$c]} | sed -e "s/${commenterArray[$c]}//" | awk '{$1=$1;print}')
            agents+=("$cNames;")
        fi
    done

    if [[ -n ${agents[@]} ]]; then
        agentsU=($(printf "%s\n" "${agents[@]}" | sort -u))
    else
        agentU=(No Responce to Customer)
    fi

    echo $subject","$status","${agentsU[@]}","$created","$closed","$amount >> /tmp/zoho_report.csv
    agents=()
    agentU=()
done

echo "Please find attaced report" | mail -s "Zoho Report" -a /tmp/zoho_report.csv user@example.com