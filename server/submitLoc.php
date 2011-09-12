<?php 
/*
 * Near Space Balloon Tracker V 1.0
 * Kevin James Hunt 2011
 * kevinjameshunt@gmail.com
 * http://www.kevinjameshunt.com
 *
 * http://github.com/kevinjameshunt/near-space-balloon-tracker
 *
 * Receives location data from device in flight, stores in database, returns commands from tracker
 *
 * Prediction data adapted from CUSF Landing Prediction Version 2  by Jon Sowman
 * http://github.com/jonsowman/cusf-standalone-predictor
 *
 */

	require("predictor/map_includes/dbinfo.php");
	
	date_default_timezone_set("Canada/Toronto");

	$longitude = $_POST['longitude'];
	$latitude = $_POST['latitude'];
	$altitude = $_POST['altitude'];
	$accuracy = $_POST['accuracy'];
	$altitudeAccuracy = $_POST['altitudeAccuracy'];
	$heading = $_POST['heading'];
	$speed = $_POST['speed'];
	$timestamp = $_POST['timestamp'];
	$tripid = $_POST['tripid'];
	$appstate  = $_POST['appstate'];
	$batlevel  = $_POST['batlevel'];

	// connect to the database
	$con = mysql_connect(localhost, $username, $password);
	if (!$con)
	{
	  die('Could not connect: ' . mysql_error());
	}
	mysql_select_db($database,$con);

	// prepare query to insert data into database
	$querySql = "INSERT INTO space_coords (longitude, latitude, altitude, accuracy, altitudeAccuracy, heading, speed, tripid, appstate, batlevel, timestamp)";
	$querySql .= " VALUES (";
	$querySql .= "'" . $longitude . "',";
	$querySql .= "'" . $latitude . "',";
	$querySql .= "'" . $altitude . "',";
	$querySql .= "'" . $accuracy . "',";
	$querySql .= "'" . $altitudeAccuracy . "',";
	$querySql .= "'" . $heading . "',";
	$querySql .= "'" . $speed . "',";
	$querySql .= "'" . $tripid . "',";
	$querySql .= "'" . $appstate . "',";
	$querySql .= "'" . $batlevel . "',";
	$querySql .= "DATE_FORMAT('" . $timestamp . "',  '%Y-%m-%d %H:%i:%s' ))";
	
	// Execute the query
	if (!mysql_query($querySql,$con))
	{
		// If it fails, we do nothing as we know another message will be sent soon.  Just dump and move on.
		//echo $querySql;
		die('Error: ' . mysql_error());
		echo "Error";
	} else {
		// If the update is successful, 
		
		// default return value should be Success
		$message = "Success";
		
		// Check to see if the trip exists in the database
		$querySql = "SELECT * FROM space_message WHERE tripid = " . $tripid;
		$show = mysql_query($querySql,$con) or die (mysql_error());
		$row = mysql_fetch_array($show);
		
		// If the trip exists, get message and then update it
		if ($row) {
			
			// Get the message to be returned to the phone
			$message = $row['message'];
			
			// If we are reporting that the transmitter has been found, update the db
			if (isset($_POST['found']) && $_POST['found'] == 1 && $message != "Found") {
				$querySql = "UPDATE space_message SET message = 'Found', ";
				$querySql .= "timestamp = DATE_FORMAT('" . $timestamp . "',  '%Y-%m-%d %H:%i:%s' ) ";
				$querySql .= "WHERE tripid = " . $tripid;
				if (!mysql_query($querySql,$con))
				{
					//echo $querySql;
					die('Error: ' . mysql_error());
					echo "Error updating message";
				}
			} else  if ($message != "Success" && $message != "Found") {
				// If there was a special message for the transmitter, we can return this back to "Success" so we aren't constantly retrieving the same message
				$querySql = "UPDATE space_message SET message = 'Success' WHERE tripid = " . $tripid;
				if (!mysql_query($querySql,$con))
				{
					//echo $querySql;
					die('Error: ' . mysql_error());
					echo "Error updating message";
				} 	
			}
		} else {
			// If it does not exist, create a new one 
			$querySql = "INSERT INTO space_message (tripid, uuid, message) VALUES (" . $tripid . ", '', 'Success')" ;
			if (!mysql_query($querySql,$con))
			{
				//echo $querySql;
				die('Error: ' . mysql_error());
				echo "Error updating message";
			}
		}
		
		// send this as the response to the transmitter
		echo $message;
		
		// close the connection
		mysql_close($con);
	}
?>