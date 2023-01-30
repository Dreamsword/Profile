#!/bin/bash

# Global settings
export ZABBIX_USERNAME=Cli
export ZABBIX_PASSWORD=CleanCopCarDonuts
hostname=$(hostname -f)
maintenance=$(zabbix-cli -C "show_host $hostname" | grep -i "in progress")
pass="R0ck3tS33d"

#Set variables
mainlog="/var/log/exim4/mainlog"

########################################
# Zabbix Script to monitor the database
########################################

postgres_connection () {
  postgres_service=$(/bin/systemctl is-active postgresql)
  connection=$(/usr/bin/pg_isready | awk -F- '{print $NF}' | awk '{$1=$1;print}')
  if [[ ${connection} != "accepting connections" && -z $maintenance ]]; then
    /bin/systemctl -q restart postgresql
    /bin/systemctl -q restart pgpool2
    if [[ $postgres_service = "failed" ]]; then
      printf "%s" "PostgreSQL failed to startup"
    else
       printf "%s" "PostgreSQL restarted due to process not running"
    fi
  else
    printf "%s" "PostgreSQL running"
  fi
}

pgpool_connection () {
  pgpool_service=$(/bin/systemctl is-active pgpool2)
  if [[ $pgpool_service != "active" && -z $maintenance ]]; then
    countPGPOOL=$(/bin/ps -aux --no-heading | /bin/grep pgpool: | /usr/bin/awk 'END {print NR}')
    if [[ $countPGPOOL -ge 2 ]]; then
      /bin/systemctl stop rslogger exim4 nginx
      /usr/bin/killall pgpool
      if [[ -S /var/run/postgresql/.s.PGSQL.5433 ]]; then
        /bin/rm /var/run/postgresql/.s.PGSQL.5433
      fi
      if [[ -S /var/run/postgresql/.s.PGSQL.9898 ]]; then
        /bin/rm /var/run/postgresql/.s.PGSQL.9898
      fi
      /bin/systemctl -q restart postgresql
      /bin/systemctl start pgpool2 nginx exim4 rslogger
      if [[ $pgpool_service != "active" ]]; then
        printf "%s" "PGPOOL still inactive"
      else
        prtinf "%s" "PGPOOL restarted"
      fi
    else
      if [[ -S "/var/run/postgresql/.s.PGSQL.5433" ]]; then
        /bin/rm /var/run/postgresql/.s.PGSQL.5433
      fi
      if [[ -S "/var/run/postgresql/.s.PGSQL.9898" ]]; then
        /bin/rm /var/run/postgresql/.s.PGSQL.9898
      fi
      /bin/systemctl -q restart pgpool2
      if [[ $pgpool_service = "failed" ]]; then
        printf "%s" "PGPOOL failed to startup"
      else
        printf "%s" "PGPOOL restarted"
      fi
    fi
  elif [[ $pgpool_service = "active" ]]; then
    printf "%s" "PGPOOL running"
  else
    printf "%s" "PGPOOL is down"
  fi
}

pgpool_backend_nodes () {
  nodes=$(/bin/sed -n "$(date +"/^%F %H:%M:/,\$p" -d "5 minutes ago")" $mainlog | grep -c 'pgpool requires at least one valid node')
  if [[ $nodes -ge 1 ]]; then
    /bin/systemctl -q restart pgpool2
    printf "%s" "PGPool restarted as no valid nodes where available"
  else
    printf "%s" "PGPool nodes available"
  fi
}

database_sockets () {
  if [[ ! -S "/var/run/postgresql/.s.PGSQL.9898" ]] ||
  [[ ! -S "/var/run/postgresql/.s.PGSQL.5433" ]] ||
  [[ ! -S "/var/run/postgresql/.s.PGSQL.5432" ]]; then
    printf "%s" "Missing sockets"
  else
    printf "%s" "All sockets present"
  fi
}

rslogger_process () {
  rslogger_service=$(/bin/systemctl is-active rslogger)
  if [[ $rslogger_service != "active" && -z $maintenance ]]; then
    /bin/systemctl -q restart rslogger
    if [[ $rslogger_service = "failed" ]]; then
      prinf "%s" "RSLogger failed to startup"
    else
      printf "%s" "RSLogger restarted"
    fi
  elif [[ $rslogger_service = "active" ]]; then
    printf "%s" "RSLogger running"
  else
    printf "%s" "RSLogger is down"
  fi
}

##################################
# Zabbix Script to monitor exim
##################################

# Create bypass branding file if not exist
if [[ ! -f /etc/exim4/acl_bypass_brandone_sender_domain ]]; then
  /usr/bin/touch /etc/exim4/acl_bypass_brandone_sender_domain
fi

# Start exim if down
exim_process () {
  exim_service=$(/bin/systemctl is-active exim4)
  if [[ $exim_service != "active" && -z $maintenance ]]; then
    /bin/systemctl -q restart exim4
    if [[ $exim_service = "failed" ]]; then
      printf "%s" "Exim failed to startup"
    else
       printf "%s" "Exim restarted due to process not running"
    fi
  elif [[ $exim_service = "active" ]]; then
    printf "%s" "Exim running"
  else
    printf "%s" "Exim is down"
  fi
}

# Check if mail loop
mail_loop () {
  mailLoop=$(/bin/sed -n "$(date +"/^%F %H:%M:/,\$p" -d "10 minutes ago")" $mainlog | grep -c 'suspected mail loop')
  ignore=$(/bin/sed -n "$(date +"/^%F %H:%M:/,\$p" -d "10 minutes ago")" $mainlog | grep 'suspected mail loop' | grep -c 'hciamerica.com')
  if [[ $mailLoop -ge 1 && $ignore -ne 1 ]]; then
    printf "%s" "$mailLoop emails as suspected mail loop"
  else
    printf "%s" "No mails in a loop"
  fi
}

# Check if exim can connect via pgpool to database
mail_db_connection () {
  dbConnection=$(/bin/sed -n "$(date +"/^%F %H:%M:/,\$p" -d "5 minutes ago")" $mainlog | /bin/grep -c 'PGSQL connection failed')
  if [[ $dbConnection -ge 1 ]]; then
    printf "%s" "Exim can't connect to the database via PGPool"
  else
    printf "%s" "Exim DB connections optimal"
  fi
}

mail_queue () {
  queue=$(echo $pass | sudo -u rocketeer -S -s sudo /usr/sbin/exim -bpc)
  printf "%s" "$queue"
}

mail_queue_size () {
  queueSize=$(echo $pass | sudo -u rocketeer -S -s sudo /usr/sbin/exipick --size)
  printf "%s" "$queueSize"
}

mail_ptr () {
  ptr=$(echo $pass | sudo -u rocketeer -S -s sudo /bin/grep -i -c -e 'forged hostname' -e 'cannot find your hostname' /var/log/exim4/mainlog)
  printf "%s" "$ptr"
}

mail_out () {
  mailOut=$(echo $pass | sudo -u rocketeer -S -s sudo /bin/grep 'H=' /var/log/exim4/mainlog | /bin/grep  '=>' | /bin/grep -c 'C=\"250')
  printf "%s" "$mailOut"
}

mail_in () {
  mailIn=$(echo $pass | sudo -u rocketeer -S -s sudo /bin/grep 'H=' /var/log/exim4/mainlog | /bin/grep  '<=' | /bin/grep -vc 'P=local')
  printf "%s" "$mailIn"
}

mail_rtf_detected () {
  rtf=$(/bin/sed -n "$(date +"/^%F %H:%M:/,\$p" -d "10 minutes ago")" $mainlog | grep -c 'it is a RTF email' | awk '{ print $3 }')
  printf "%s" "RTF email detected - $rtf"
}

mail_red_limit () {
  redLine=$(/bin/grep -c 'no immediate delivery: load average' $mainlog)
  bypassDomain="/etc/exim4/acl_bypass_brandone_sender_domain"
  # Calculate if a file has been modified recently
  waitModify=1800
  currentTime=$(date +%s)
  bypassDomainTime=$(stat $bypassDomain -c %Y)
  bypassDomainTimeDiff=$((currentTime - bypassDomainTime))

  if [[ $redLine -ge 1 && -z $maintenance ]]; then
    redLineTreshold=$(/bin/sed -n "$(date +"/^%F %H:%M:/,\$p" -d "5 minutes ago")" $mainlog | grep -c 'no immediate delivery: load average')
    if [[ $redLineTreshold -ge 5 ]]; then
      printf "%s" "Server hit Redline limit, bypassing branding"
      if [[ $bypassDomainTimeDiff -gt $waitModify ]]; then
        printf "%s" "Redline limit reached, not bypassing, file modified recently"
        domains=()
          while read -r output_line; do
          domains+=("$output_line")
          done < <(/usr/bin/sudo -upostgres /usr/bin/psql -d rocketseed2 -t -c "select domain from senderdomains;")
        printf "%s" "${domains[*]}" | tr ' ' '\n' | sort -u | tr '\n' ' ' | tr " " "\n" | awk 'NF > 0' > $bypassDomain
      fi
    else
      echo '' > "$bypassDomain"
    fi
  else
    printf "%s" "Server performing optimally"
  fi
}

mail_brandone_stuck () {
  mailStuck=$(/bin/grep "brandone transport returned 75" $mainlog)
  bypassError75="/etc/exim4/bypass_error75_IDs"
  mailAge=$mailStuck | awk '!seen[$3] {print} {++seen[$3]}' | awk '{ print $3 }' | exiqgrep -i | xargs exiqgrep -o 3600 | awk '{ print $3 }' | awk 'NF > 0'
  count=$($mailAge | wc -l)
  if [[ $count -ge 1 ]]; then
    $mailAge > $bypassError75
    printf "%s" "$count mails pushed for delivery"
  else
    printf "%s" "No mails stuck in the queue"
  fi
}

exim_stats () {
  eximstats=$(/usr/sbin/eximstats -nr -nt -tnl /var/log/exim4/mainlog.1)

  ReceivedMessages=$(grep Received  <<< "$eximstats" | awk '{print $3}')
  ReceivedVolume=$(grep Received <<< "$eximstats" | awk '{print $2}')
  DeliveredMessages=$(grep Delivered <<< "$eximstats" | awk '{print $3}')
  DeliveredVolumes=$(grep Delivered <<< "$eximstats" | awk '{print $2}')
  DeliveredAddresses=$(grep Delivered <<< "$eximstats" | awk '{print $4}')
  ReceivedDelayed=$(grep Received <<< "$eximstats" | awk '{print $6}')
  ReceivedFailed=$(grep Received <<< "$eximstats" | awk '{print $8}')
  RejectsMessages=$(grep 'Rejects' <<< "$eximstats" | awk '{print $2}')
  MailsPerHour=$(grep -A 56 'Messages received per hour' <<< "$eximstats")

  declare -A list
  list+=([ReceivedMessages]=$ReceivedMessages
  [ReceivedVolume]=$ReceivedVolume
  [DeliveredMessages]=$DeliveredMessages
  [DeliveredVolumes]=$DeliveredVolumes
  [DeliveredAddresses]=$DeliveredAddresses
  [ReceivedDelayed]=$ReceivedDelayed
  [ReceivedFailed]=$ReceivedFailed
  [RejectsMessages]=$RejectsMessages)

  for i in "${!list[@]}"; do
    printf "%s\t%s\n" "$i" "${list[$i]}"
  done

  printf "%s" "$MailsPerHour"
}

##################################
# Zabbix Script to monitor nginx
##################################

nginx_process () {
  nginx_service=$(/bin/systemctl is-active nginx)
  if [[ $nginx_service != "active" && -z $maintenance ]]; then
    /bin/systemctl -q restart nginx
    if [[ $nginx_service = "failed" ]]; then
      printf "%s" "Nginx failed to startup"
    else
       printf "%s" "Nginx restarted due to process not running"
    fi
  elif [[ $nginx_service = "active" ]]; then
    printf "%s" "Nginx running"
  else
    printf "%s" "Nginx is down"
  fi
}

nginx_webpage () {
  page=$(curl -sSfk https://$hostname | grep -i "user account")

  if [[ -n $page ]]; then
    printf "%s" "Webpage is up"
  else
    printf "%s" "Webpage is down"
  fi
}

######################################
# Zabbix Script to monitor Disk Usage
######################################

get_disk () {
  df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 " " $6}'
}

disk_check () {
  issue="";
  get_disk | (while read output;
  do
    usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1)
    partition=$(echo $output | awk '{ print $3 }')

    if [[ $usep -ge 90 ]]; then
      if [[ $partition == "/" ]]; then
        # Delete old files in the tmp directory.
        echo $pass | sudo -u rocketeer -S -s sudo find /tmp -type f -mtime +0 -exec rm -f {} +
        echo $pass | sudo -u rocketeer -S -s sudo find /tmp -type d -mtime +0 -exec rm -rf {} +

        # Delete old stored messages.
        find /var/rocketseed/ -type d | while read output;
        do
          echo $pass | sudo -u rocketeer -S -s sudo find $output -type f -mtime +0 -exec rm -f {} +
        done

        # Delete oldest backup file if older than 5 days.
        echo $pass | sudo -u rocketeer -S -s sudo find /var/rsbackups/ -type f -mtime +5 -exec rm -rf {} +

        # Delete user files older than a week.
        echo $pass | sudo -u rocketeer -S -s sudo find /home/ -type d -not -path '*/\.*' -maxdepth 1 | while read output;
        do
          echo $pass | sudo -u rocketeer -S -s sudo find $output -type f -mtime +7 -size +200M -exec rm -f {} +
        done

        # Delete old log files
        find /var/log/ -type f -mtime +14 -not -regex ".*\.log" -not -regex ".*\.err" -not -name "syslog" -exec rm -f {} +

        issue+="$partition "

      elif [[ $partition == "/boot" ]]; then
        # Remove old kernel versions.
        echo $pass | sudo -u rocketeer -S -s sudo apt-get autoremove -y > /dev/null 2>&1
        issue+="$partition "

      else
        issue+="$partition "
      fi
    fi
  done

  # Now report on what you found.
  afterClean=$(df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $6 }' | grep -e '\/$' | awk '{ print $1 }' | cut -d'%' -f1)
  if [[ $afterClean -ge 90 ]]; then
    printf "%s" "Disk space issue after auto clean on $issue"
  else
    printf "%s" "Disk Space Optimal"
  fi
  )
}

######################################
# Zabbix Script to monitor Drupal Cron
######################################

drupal_cron () {
  cd /var/www/drupal-7
  # Check when cron last ran.
  last_run=$(echo $pass | sudo -u rocketeer -S -s drush vget cron_last --exact)
  # Get the current timestamp - 1 hours
  now_less_1h=$(date -d -1hours +"%s")

  if [[ $now_less_1h -gt $last_run ]]; then
    now=$(date +"%s")
    last_run_diff_hours=$((($now-$last_run)/60/60))
    if [[ $last_run_diff_hours -gt 2 ]]; then
      printf "%s" "Drupal Cron has not run for $last_run_diff_hours hours"
    else
      echo $pass | sudo -u rocketeer -S -s drush cron
      printf "%s" "Drupal Cron initiated"
    fi
  else
    printf "%s" "Drupal Cron functioning"
  fi
}

######################################
# Zabbix Script to monitor misc items
######################################

restart_req () {
  if [[ -f /var/run/reboot-required ]]; then
    printf "%s" "Reboot Required"
  else
    printf "%s" "OK"
  fi
}

check_spf () {
  domains=()
  while read -r output_line; do
  domains+=("$output_line")
  done < <(/usr/bin/sudo -upostgres /usr/bin/psql -d rocketseed2 -t -c "SELECT DISTINCT domain FROM senderdomains;" | sed '$d')

  missing=""
  invalid=""
  for d in "${domains[@]}"
  do
    find=$(dig +short TXT $d | grep "v=spf1" | grep rocketseed.com)
    spf_count=$(echo $found | wc -l)

    if [[ -z $find ]]; then
      missing+="\"$d\" "
    elif [[ $spf_count -gt 2 ]]; then
      invalid+="\"d\" "
    fi
  done

  if [[ -n $missing || -n $invalid ]]; then
    {
      echo "Domains With No Rocketseed SPF:"
      echo "$missing"
      echo ""
      echo "Domains With Invalid SPF's:"
      echo "$invalid"
    }
  else
    printf "%s" "Rocketseed SPF Found On All Domains"
  fi
}

check_cname () {
  tracker_domains=()
  while read -r output_line; do
  tracker_domains+=("$output_line")
  done < <(/usr/bin/sudo -upostgres /usr/bin/psql -d rocketseed2 -t -c "SELECT DISTINCT tracker_domain FROM senderdomains where tracker_domain != '';" | sed '$d')

  missing=""
  invalid=""
  for td in "${tracker_domains[@]}"
  do
    cname=$(dig +short cname $td)

    if [[ -z $cname ]]; then
      missing+="$td "
    elif [[ $cname != $hostname ]]; then
      invalid="$td "
    fi
  done

  if [[ -n $missing || -n $invalid ]]; then
    {
      echo "CNAME missing for:"
      echo "$missing"
      echo ""
      echo "Invalid CNAME:"
      echo "$invalid"
    }
  else
    printf "%s" "CNAME's Found On All Tracker Domains"
  fi

}

########################################
# Zabbix Script to monitor email latency
########################################

latency_check () {
  emails=()
  while read -r output_line; do
  emails+=("$output_line")
  done < <(/usr/bin/sudo -upostgres /usr/bin/psql -d rocketseed2 -t -c "select i.mta_id, count(*), i.message_size, i.queued_time, max(o.delivered_time) lastrecipient, max(o.delivered_time)-i.queued_time latency from mtalog i join maillog m on m.mta_id = i.mta_id join mtalog o on m.mailid = o.mailid where i.queued_time > now() - interval '1 hour' group by i.mta_id having every(o.delivered_time is not null) order by latency desc limit 1;" | sed '$d')

  for l in "${emails[@]}"
  do
    IFS='| ' read -r -a exploded <<< "$emails"
    if [[ ${exploded[1]} == 1 ]]; then
      IFS=':' read -r -a time <<< "${exploded[7]}"
      if [[ ${time[0]} -ne 00 ]]; then
        printf "%s" "Mails took ${time[0]} hours to deliver, example ${exploded[0]}"
      elif [[ ${time[1]} -gt 25 ]]; then
        printf "%s" "Mails took ${time[1]} minutes to deliver, example ${exploded[0]}"
      else
       printf "%s" "Mails are processed optimally"
      fi
    fi
  done
}

####################################################
# Zabbix Script to monitor spare server backup level
####################################################

spare_backup_level () {
  spare=$(cd /var/www/drupal-7/sites/worldclass/ && drush vget rs_installation_live | awk '{ print $2 }' | sed s/"'"//g)

  if [[ $spare == 0 ]]; then
    backup=$(/usr/bin/sudo -upostgres /usr/bin/psql -d rocketseed2 -t -c "select queued_time from "mtalog" where delivered_time > now() - '24 hours'::interval and last_response is null limit 1;" | sed '$d')
    if [[ -z $backup ]]; then
      printf "%s" "The spare have not synced recently"
    else
      printf "%s" "The spare is up to date"
    fi
  fi
}

#######################################
# Zabbix Script to monitor blacklisting
#######################################

black_list_check () {
  blacklists="
    b.barracudacentral.org
    bb.barracudacentral.org
    cidr.bl.mcafee.com
    bl.spamcop.net
    zen.spamhaus.org
    ips.backscatterer.org
    0spamurl.fusionzero.com
    l1.apews.org
    bsb.empty.us
    bsb.spamlookup.net
    dnsbl.othello.ch
    ubl.nszones.com
    rhsbl.rymsho.ru
    rhsbl.scientificspam.net
    nomail.rhsbl.sorbs.net
    badconf.rhsbl.sorbs.net
    rhsbl.sorbs.net
    fresh.spameatingmonkey.net
    fresh10.spameatingmonkey.net
    fresh15.spameatingmonkey.net
    multi.surbl.org
    uribl.swinog.ch
    dob.sibl.support-intelligence.net
    uri.blacklist.woody.ch
    rhsbl.zapbl.net
    hostkarma.junkemailfilter.com
    nobl.junkemailfilter.com
    iddb.isipp.com
    list.anonwhois.net
    cbl.abuseat.org
  "

  listed=()
  ip=$(dig +short $hostname)
  if [[ -n $ip ]]; then
    reverse=$(echo $ip |
    sed -ne "s~^\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)\.\([0-9]\{1,3\}\)$~\4.\3.\2.\1~p")

    loopthroughblacklists() {

      reverse_dns=$(dig +short -x $ip)

      for bl in ${blacklists} ; do
        check="$(dig +short -t a ${reverse}.${bl})"

        if [[ -n $check ]]; then
          listed+=("$bl")
        fi
      done
    }

    if [[ -n $listed ]]; then
      printf "%s" "$hostname [blacklisted] (${ip})"
    else
      printf "%s" "OK"
    fi

    loopthroughblacklists

  else
    printf "%s" "No DNS record for this server found"
  fi
}

$*
