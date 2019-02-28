#!/bin/php
<?php
// Get Domain variable from command line
$domain=$argv[1];

// Set txt record count to zero
$txt_record_count=0;

// Get only TXT records for the domain
$TXT_ARRAY = dns_get_record($domain, DNS_TXT);
echo "$domain\n";

// Count how man TXT records contain spf1 records
foreach ( $TXT_ARRAY as $key=>$value){
        if (strpos($value['txt'], 'spf1') !== false) {
        $txt_record_count++;
}
}

// If there are more than 1 TXT SPF records then the SPF is invalidated
if ( $txt_record_count > "1" ){
	echo "More than one TXT record - FAILED\n";
}
else {
	echo "Only one TXT record - PASSED\n";
}

// Check for old type SPF records which are no longer used
$SPF_CHECK = shell_exec("dig SPF $domain |grep SPF |sed -e '/;.*/d'");
if(empty($SPF_CHECK)) {
	echo "No old SPF type record - PASSED\n";
}
else {

    echo "Old SPF type record found - FAILED\n";
    
}
?>
