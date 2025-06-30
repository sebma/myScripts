#!/usr/bin/env php
<?php
include db_cli_config.php;
$mysqli = new mysqli("localhost", "username", "password", "database");
if ($mysqli->connect_error) { die("Connection failed: " . $mysqli->connect_error); }
echo "Connected successfully";
?>
