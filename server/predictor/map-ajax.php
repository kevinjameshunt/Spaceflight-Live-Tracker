<?php

/*
 * Near Space Balloon Tracker V 1.0
 * Kevin James Hunt 2011
 * kevinjameshunt@gmail.com
 * http://www.kevinjameshunt.com
 *
 * http://github.com/kevinjameshunt/near-space-balloon-tracker
 *
 * AJAX functions for retrieving location and prediction data from server
 *
 * Prediction data adapted from CUSF Landing Prediction Version 2  by Jon Sowman
 * http://github.com/jonsowman/cusf-standalone-predictor
 *
 */
 
require("map_includes/dbinfo.php");

define("PREDSTORE_PATH", "predstore/");
define("FLIGHT_CSV", "flight_path.csv");

function parseToXML($htmlStr) 
{ 
$xmlStr=str_replace('','&lt;',$htmlStr); 
$xmlStr=str_replace(':','&gt;',$xmlStr); 
$xmlStr=str_replace('"','&quot;',$xmlStr); 
$xmlStr=str_replace("'",'&#39;',$xmlStr); 
$xmlStr=str_replace("&",'&amp;',$xmlStr); 
return $xmlStr; 
} 

$action = $_GET['action'];

switch($action) {
case "getTripData":
	$lastTimestamp = $_GET['timestamp'];
	$latestMessage = $_GET['latestmessage'];

	// Opens a connection to a MySQL server
	$connection=mysql_connect (localhost, $username, $password);
	if (!$connection) {
	 die('Not connected : ' . mysql_error());
	}
	
	// Set the active MySQL database
	$db_selected = mysql_select_db($database, $connection);
	if (!$db_selected) {
	 die ('Can\'t use db : ' . mysql_error());
	}
	
	// Get Last Updated ID
	$query = "SELECT * FROM space_message WHERE 1 ORDER BY id DESC LIMIT 1 ";
	$result = mysql_query($query);
	if (!$result) {
	 die('Invalid query: ' . mysql_error());
	}
	$row = @mysql_fetch_assoc($result);
	$tripid = $row['tripid'];
	$uuid = $row['uuid'];
	$message = $row['message'];
	if ($message == "Found") {
		$timestamp = $row['timestamp'];
	} else {
		$timestamp = "";	
	}
	
	$result = null;
	
	// Select all the rows in the markers table
	$querySql = "SELECT * FROM space_coords WHERE tripid=" . $tripid;
	if ($lastTimestamp != "") {
		$querySql .= " AND DATE_FORMAT(timestamp,  '%Y-%m-%d %h:%i:%s' )>= DATE_FORMAT('" . $lastTimestamp . "',  '%Y-%m-%d %h:%i:%s' )";
	}
	
	$result = mysql_query($querySql);
	if (!$result) {
	 die('Invalid query: ' . mysql_error());
	}

	$json = array();
	$json['tripData'] = array();
	$json['tripData']['tripid'] = $tripid;
	$json['tripData']['uuid'] = $uuid;
	$json['tripData']['message'] = $message;
	$json['tripData']['timestamp'] = $timestamp;
	$json['tripData']['latestMessage'] = $latestMessage;
	
	// Start markers object, echo parent node
	$json['markers'] = array();
	
	// Iterate through the rows, printing XML nodes for each
	$count = 0;
	while ($row = @mysql_fetch_assoc($result)){
		// ADD TO XML DOCUMENT NODE
		 $json['markers'][$count] = array();
		 $json['markers'][$count]['lat'] = $row['latitude'];
		 $json['markers'][$count]['lon'] = $row['longitude'];
		 $json['markers'][$count]['id'] = $row['id'];
		 $json['markers'][$count]['alt'] = $row['altitude'];
		 $json['markers'][$count]['state'] = $row['appstate'];
		 $json['markers'][$count]['bat'] = $row['batlevel'];
		 $json['markers'][$count]['timestamp'] = $row['timestamp'];
		 $count +=1;
	}

	$encoded = json_encode($json);
	die($encoded);
	break;
	
case "getCSVLongTerm":
    $uuid = $_GET['uuid'];
    $tryfile = PREDSTORE_PATH . $uuid . "/" . FLIGHT_CSV;
    if(!file_exists($tryfile)) return false;
    $fh = fopen($tryfile, "r");
    $data = array();
    while (!feof($fh)) {
        $line = trim(fgets($fh));
        array_push($data, $line);
    }
    $returned = json_encode($data);
    echo $returned;
    break;

default:
    echo "Couldn't interpret 'action' variable";
    break;

}


?> 