<?php

$list = array(
  "Red Dead Redemtion 2 [xbox]",
  "FarCry 5 [xbox]",
  "Tom Clancy Wildlands [xbox]",
  "Fallout 4 Expansion [xbox]",
  "Assassin's Creed IV Black Flag [xbox]",
  "Trials of the Blood Dragon [xbox]",
  "Gwent [xbox]",
  "Batman Telltale [xbox]",
  "Mincraft: Story Mode Telltale [xbox]",
  "Deus Ex: Mankind Divided [xbox]",
  "Lords of the Fallen [xbox]",
  "Game of Thrones Telltale [xbox]",
  "Dishonored [xbox]",
  "Tales from the Borderlands [xbox]",
  "Second Son [ps4]",
  'Uncharted [ps4]',
  "Star Wars The Old Republic [PC]",
  "Two Point Hospital [PC]",
  "Battlefleet Gothic [PC]",
  "Throne Breaker [PC]",
);

$finished = array(
  'Uncharted [ps4]'
);

$random = array_diff($list,$finished);

$result = $random[mt_rand(0, count($random))];
echo "\n" . $result . "\n\n";

?>