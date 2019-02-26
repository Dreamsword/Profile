#!/usr/bin/env bash

servers=("server.example.com" "server2.example.com" "server3.example.com")

blacklists="
  b.barracudacentral.org
  bb.barracudacentral.org
  cidr.bl.mcafee.com
  bl.spamcop.net
  dbl.spamhaus.org
  pbl.spamhaus.org
  sbl-xbl.spamhaus.org
  zen.spamhaus.org
  ips.backscatterer.org
  0spamurl.fusionzero.com
  l1.apews.org
  dnsbl.aspnet.hu
  bsb.empty.us
  bsb.spamlookup.net
  ex.dnsbl.org
  in.dnsbl.org
  dnsbl.othello.ch
  ubl.nszones.com
  url.rbl.jp
  rhsbl.rymsho.ru
  rhsbl.scientificspam.net
  nomail.rhsbl.sorbs.net
  badconf.rhsbl.sorbs.net
  rhsbl.sorbs.net
  fresh.spameatingmonkey.net
  fresh10.spameatingmonkey.net
  fresh15.spameatingmonkey.net
  dbl.spamhaus.org
  multi.surbl.org
  uribl.swinog.ch
  dob.sibl.support-intelligence.net
  uri.blacklist.woody.ch
  rhsbl.zapbl.net
  hostkarma.junkemailfilter.com
  reputation-domain.rbl.scrolloutf1.com
  reputation-ns.rbl.scrolloutf1.com
  nobl.junkemailfilter.com
  iddb.isipp.com
  list.anonwhois.net
"

for s in "${servers[@]}"
do

reverse=$(echo $s |
sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")

loopthroughblacklists() {

  reverse_dns=$(dig +short -x $s)

  ASP=${reverse_dns:----}

  for bl in ${blacklists} ; do

      listed="$(dig +short -t a ${reverse}.${bl})"

    if [[ $ASP == server.example.com ]] && [[ $listed == 127.0.0.2 ]]; then
        /usr/bin/zabbix_sender -z <zabbix server ip> -s "server.example.com" -k blacklist -o "$s ${bl} [blacklisted] (${listed})" 
    elif [[ $ASP == server.example.com ]]; then
        /usr/bin/zabbix_sender -z <zabbix server ip> -s "server.example.com" -k blacklist -o "$s OK" 
    fi    
        
    if [[ $ASP == server2.example.com ]] && [[ $listed == 127.0.0.2 ]]; then
        /usr/bin/zabbix_sender -z <zabbix server ip> -s "server2.example.com" -k blacklist -o "$s ${bl} [blacklisted] (${listed})"
    elif [[ $ASP == server2.example.com ]]; then
        /usr/bin/zabbix_sender -z <zabbix server ip> -s "server2.example.com" -k blacklist -o "$s OK"
    fi
        
    if [[ $ASP == server3.example.com ]] && [[ $listed == 127.0.0.2 ]]; then
        /usr/bin/zabbix_sender -z <zabbix server ip> -s "server3.example.com" -k blacklist -o "$s ${bl} [blacklisted] (${listed})"
    elif [[ $ASP == server3.example.com ]]; then
        /usr/bin/zabbix_sender -z <zabbix server ip> -s "server3.example.com" -k blacklist -o "$s OK"
    fi
    
  done
}

loopthroughblacklists
  
  done