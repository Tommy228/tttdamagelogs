<?php
$db_config = array (
	'host' => 'localhost',
	'username' => '',
	'passwd' => '',
	'dbname' => '',
	'port' => ini_get("mysqli.default_port"),
	'socket' => ini_get("mysqli.default_socket"),
	'table' => 'damagelog_oldlogs',
	'table_weapons' => 'damagelog_weapons',
);
$timezone = 'Europe/Paris'; // See https://php.net/manual/en/timezones.php
$check_for_empty = FALSE; // Set it to TRUE if you want to remove empty years, months and days from the list. This will do much more SQL queries, so it is not recommended.
?>
