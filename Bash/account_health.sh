#!/bin/bash

do_sql () {
   sudo -upostgres psql -d rocketseed2 -t -c "$1"
}

rm -rf /tmp/health.txt
rm -rf /tmp/not_routing.txt
rm -rf /tmp/notracking.txt

Server=$(hostname -f)
NoReseller=$(do_sql "select id FROM \"mstAccount\" where name ILIKE '%Rocketseed%' and \"parentAccountId\" IS NULL;")
Account=$(do_sql "select id from \"mstAccount\" where name not similar to '%(Rocketseed|test|Test|deleted)%' and \"templateFormat\" is not null and \"parentAccountId\" not in ($NoReseller) order by id;" | sed '$!s/$/,/')
DateNow=$(date +"%F" -d "now")
DateWeek=$(date +"%F" -d "-1 week")
DateMonth=$(date +"%F" -d "-3 months")
DateSec=$(date -d "$DateMonth" +%s)

for f in $Account
do
  AccountName=$(do_sql "select name from \"mstAccount\" where id = '$f' order by id;")
  Seats=$(do_sql "select seats from \"mstAccount\" where id = '$f';")
  BannerBase=$(do_sql "select edited::date from \"mstTemplate\" where \"parentAccountId\" = '$f' and name is not null order by edited desc limit 1;")
  ActiveSenders=$(do_sql "SELECT \"apiReportKeyNumbers\"('$DateWeek', '$DateNow', '$f', null, null);" | tr -d '()' | tr -d '""' | tr ',' ':' | head -n 1 | tr -dc '0-9')
  DormantSenders=$(do_sql "SELECT \"apiReportKeyNumbers\"('$DateWeek', '$DateNow', '$f', null, null);" | tr -d '()' | tr -d '""' | tr ',' ':' | sed -n 2p | tr -dc '0-9')
  TotalBrandedSenders=$(do_sql "SELECT \"apiReportCurrentSenders\"('$f', '7 days');" | sed -e 's/(.*",//;s/)$//;s/,/ /g' | awk '{print $4}')
  TotalEmails=$(do_sql "SELECT \"apiReportKeyNumbers\"('$DateWeek', '$DateNow', '$f', null, null);" | tr -d '()' | tr -d '""' | tr ',' ':' | sed -n 3p | tr -dc '0-9')
  BrandedEmails=$(do_sql "SELECT \"apiReportKeyNumbers\"('$DateWeek', '$DateNow', '$f', null, null);" | tr -d '()' | tr -d '""' | tr ',' ':' | sed -n 4p | tr -dc '0-9')
  UnbrandedEmails=$(do_sql "SELECT \"apiReportKeyNumbers\"('$DateWeek', '$DateNow', '$f', null, null);" | tr -d '()' | tr -d '""' | tr ',' ':' | sed -n 5p | tr -dc '0-9')
  CheckSenderGroup=$(do_sql "select \"priSaveTagCategory\"(NULL, $f, 'Sender Groups');")
  CheckAutoCreatedID=$(do_sql "select \"apiGetTagByNameParentCategory\"('Auto Created Senders', NULL, $CheckSenderGroup);")
  TotalAutoCreated=$(do_sql "select count(*) from \"lnkSenderTag\" where \"tagId\" = '$CheckAutoCreatedID';")
  
  BannerCreated=$(date -d "$BannerBase" +%s )
   
   TemplateID=()
     while read -r output_line; do
     TemplateID+=("$output_line")
     done < <(do_sql "select distinct \"parentTemplateId\" from \"mstTemplate\" where \"parentTemplateId\" is not null and \"parentTemplateId\" != '0' and \"parentAccountId\" = '$f' and active = 't' and deleted = 'f';" | sed '$d')
     
   lenghtT=${#TemplateID[@]}
   if [[ $lenghtT != 0 ]]; then
   
    for (( t = 0 ; t<$lenghtT ; t++ ))
    do
      NoTracking=()
        while read -r output_line; do
        NoTracking+=("$output_line")
        done < <(do_sql "select id from \"mstTracker\" where id = '${TemplateID[t]}' and tracked = 'false';" | sed '$d')
    done
   fi

   NoTrackingTotal=0
   
    lenghtNT=${#NoTracking[@]}
    if [[ $lenghtNT != 0 ]]; then
      
     for (( n = 0 ; n<$lenghtNT ; n++ ))
     do
       NoTrackingTotal=$((NoTrackingTotal + 1))
       echo "http://$Server/emailtemplate/edit/Template/${NoTracking[n]}/0/$f?destination=emailtemplate/branding/$f/Template" >> /tmp/notracking.txt
       ItemsNoTracking=()
          while read line; do
          ItemsNoTracking+=($line)
          done < <(cat /tmp/notracking.txt)
      done
    fi
     
   if [[ -z $NoTrackingTotal ]]; then
   NoTrackingTotal=0
   fi
   
   if [[ $TotalEmails != 0 ]]; then
   BrandedPercentage=$(awk "BEGIN { pc=100*${TotalBrandedSenders}/${ActiveSenders}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
   else
   BrandedPercentage=0
   fi
  
   if [ $BannerCreated -le $DateSec ]; then
   BannerOld="The Latest Assigned Banner is Three or More Months Old"
   else
   BannerOld="Banners are Recent"
   fi
   
   if [[ -z $TotalAutoCreated ]]; then
   TotalAutoCreated=0
   fi
  
   if [[ $SenderTotal != 0 ]]; then
   {
   echo "*** ${AccountName// } ***"                                                                                                                                               
   echo ""                                                                                                                                                                        
   echo "Total Licensed Seats: ${Seats// }"                                                                                                                                       
   echo ""                                                                                                                                                   
   echo "Total Auto Created Senders: ${TotalAutoCreated// }"                                                                                                                      
   echo ""
   echo "Total Active Senders (Last 7 Days): $ActiveSenders"
   echo ""
   echo "Total Branded Senders (Last 7 Days): $TotalBrandedSenders"
   echo ""                                                                                                                                                                                                                                                                                                                                             
   echo "Total Dormant Senders (Last 7 Days): $DormantSenders"                                                                                                                      
   echo ""                                                                                                                                                                        
   echo "Total Branded Mails (Last 7 Days): ${BrandedEmails// }"                                                                                                                  
   echo ""                                                                                                                                                                        
   echo "Total Unbranded Mails (Last 7 Days): ${UnbrandedEmails// }"                                                                                                              
   echo ""                                                                                                                                                                        
   echo "Branded Percentage: $BrandedPercentage%"                                                                                                                                 
   echo ""                                                                                                                                                                        
   echo "Total Templates With No Tracking: $NoTrackingTotal"                                                                                                                      
   echo ""                                                                                                                                                                        
   echo "$BannerOld"                                                                                                                                                              
   echo "" 
   } > /tmp/health.txt
    if [[ $NoTrackingTotal != 0 ]]; then
      {
      echo "Template ID's with no Tracking"
      echo ""
      } >> /tmp/health.txt
    lenghtN=${#ItemsNoTracking[@]}
    for (( n = 0 ; n<$lenghtN ; n++ ))
    do
      echo "${ItemsNoTracking[n]}" >> /tmp/health.txt
    done
    mail -s "${AccountName// } - Templates With No Tracking not 0" hein.reyneke@rocketseed.com < /tmp/health.txt
    elif [[ $BrandedPercentage -le 50 ]]; then
    mail -s "${AccountName// } - Branded Percentage Less Than 50%" hein.reyneke@rocketseed.com < /tmp/health.txt
    elif [[ $BannerOld == "The Latest Assigned Banner is Three or More Months Old" ]]; then
    mail -s "${AccountName// } - Banners Older Than 3 Months" hein.reyneke@rocketseed.com < /tmp/health.txt
    fi
   fi
  
done
