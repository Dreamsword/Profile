<?php

// Tell php that we are dealing with the localhost.
$_SERVER["REMOTE_ADDR"] = '127.0.0.1';

// Bootstrap Drupal.
$drupaldir = '/var/www/drupal-7/';
if (!file_exists($drupaldir)) {
  $drupaldir = '/var/www/drupal/';
  $drupalVersion = 6;
}
define('DRUPAL_ROOT', $drupaldir);
require_once DRUPAL_ROOT . '/includes/bootstrap.inc';
drupal_bootstrap(DRUPAL_BOOTSTRAP_FULL);

// Connect to the DB and get some html to validate
db_set_active('rocketseed');
if ($drupalVersion == 6) {
  $result = [];
  // Below you can change the location where your html is located, mine lives in a database
  $query = db_query("SELECT id, \"parentAccountId\", \"parentTemplateId\", html FROM \"mstTemplate\" WHERE \"templateType\" = 'Insert';");
  while ($row = db_fetch_object($query)) {
    $result[] = $row;
  }
  $query = $result;
}
else {
  // Below you can change the location where your html is located, mine lives in a database
  $query = db_query("SELECT id, \"parentAccountId\", \"parentTemplateId\", html FROM \"mstTemplate\" WHERE \"templateType\" = 'signature';")->fetchAll();
}
db_set_active('default');

$issues = [];
// Look through each row for html
foreach ($query as $rows) {
  $html = $rows->html;
  $template_id = $rows->id;
  $parent_account_id = $rows->parentAccountId;
  $parent_template_id = $rows->parentTemplateId;

  // Lets find all the @ tags.
  preg_match_all('/\@(.*?)\@/', $html, $matches);
  foreach ($matches[0] as $match) {
    // Has there been issues found?
    if (isInvalidHTML($match)) {
      $issues[$template_id]['invalid'] = 'TRUE';
      $issues[$template_id]['parentAccountId'] = $parent_account_id;
      $issues[$template_id]['parentTemplateId'] = $parent_template_id;
    }
  }
}

// Print the results to a file in tmp
$file = "/tmp/invalid_inserts_html.txt";
$results = print_r($issues, TRUE);
file_put_contents($file, $results);

$totalInvalidInserts = count($issues);
echo "***********************************************************************\n";
echo "Total Invalid Inserts: $totalInvalidInserts\n";
if ($totalInvalidInserts > 0) {
  echo "A file invalid_inserts_html.txt was created in /tmp with the list \n";
}
echo "***********************************************************************\n";

/**
 * Checks if the html is Invalid that it was givin.
 * The first pregmatch (start) matches the html tag start as well as all text up to the
 * closing >.
 *
 * The second pregmatch (end) matches the closing tag exactly.
 */
function isInvalidHTML($html) {
  preg_match_all('#<([a-z]+)[^>]*>#i', $html, $start, PREG_OFFSET_CAPTURE);
  preg_match_all('#<\/([a-z]+)>#i', $html, $end, PREG_OFFSET_CAPTURE);
  $start = $start[1];
  $end = $end[1];
  $issue = FALSE;

  // The html tags that dont have / need a closing tag
  $dontMatch = [
  'br',
  'area',
  'base',
  'col',
  'command',
  'embed',
  'hr',
  'img',
  'input',
  'keygen',
  'link',
  'meta',
  'param',
  'source',
  'track',
  'wbr',
  ];

  // We check the start tag and in some weird cases the end tag if it matches the dontMatch
  // above and if it does not it will continue the parser.
  if (!in_array($start[0][0], $dontMatch) && !in_array($end[0][0], $dontMatch)) {
    $i = 0;
    // first check if the end html tag is not the same as the start tag, then
    // check if the there is an orphaned end tag in the html. Note this only
    // checks for html validility between @ tags.
    if ($end[$i][0] != $start[$i][0] || $end[$i][1] < $start[$i][1]) {
      $issue = TRUE;
    }
    $i++;
  }

  return $issue;
}

?> 
