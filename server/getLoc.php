<?php
/*
 * Near Space Balloon Tracker V 1.0
 * Kevin James Hunt 2011
 * kevinjameshunt@gmail.com
 * http://www.kevinjameshunt.com
 *
 * http://github.com/kevinjameshunt/near-space-balloon-tracker
 *
 * Gets live location and prediction data from server, returns as XML
 *
 * Prediction data adapted from CUSF Landing Prediction Version 2  by Jon Sowman
 * http://github.com/jonsowman/cusf-standalone-predictor
 *
 */

	require("predictor/map_includes/dbinfo.php");
	
	date_default_timezone_set("Canada/Toronto");
	
	
	/// Update the database with a new trip, uuid, and/or message to send to the transmitter
	/// =============================
	
	
	$tripid = $_POST['tripid'];
	$lastTimestamp = $_POST['lastTimestamp'];
	$desiredaccuracy = $_POST['desiredaccuracy'];
	$replaceUUID = $_POST['replaceUUID'];
	$sendPred = $_POST['sendPred'];
	
	// set defaults
	$conflictUUID = "";
	$uuid = "";
	if ($desiredaccuracy == "") {
		$desiredaccuracy = "Success";
	} 
	
	
	if (isset($_POST['uuid']))
		$uuid = $_POST['uuid'];
	
	$lastTimestamp = urldecode($lastTimestamp);
	
	
	// connect to the database
	$con = mysql_connect(localhost, $username, $password);
	if (!$con)
	{
	  die('Could not connect: ' . mysql_error());
	}

	mysql_select_db($database,$con);
	
	
	
	// See if the trip already exists
	$querySql = "SELECT * FROM space_message WHERE tripid = " . $tripid;
	$show = mysql_query($querySql,$con) or die (mysql_error());
	$row = mysql_fetch_array($show);
	
	// If it exists
	if ($row) {
		// If the trip has not been found yet
		if ($row['message'] != "Found") {
			if ($uuid != "" && $row['uuid'] == "") {
				// If a uuid has been sent and there isn't a uuid in the database
				$querySql = "UPDATE space_message SET message = '" . $desiredaccuracy . "', uuid='" . $uuid . "' WHERE tripid = " . $tripid;
			} else if (isset($_POST['replaceUUID']) && $replaceUUID == 1) {
				// if there was a conflicting uuid and replaceUUID has been set
				$querySql = "UPDATE space_message SET message = '" . $desiredaccuracy . "', uuid='" . $uuid . "' WHERE tripid = " . $tripid;
			} else {
				// Just update the message
				$querySql = "UPDATE space_message SET message = '" . $desiredaccuracy . "' WHERE tripid = " . $tripid;
				
				// Check for conflicting uuids
				$oldUUID = $row['uuid'];
				if (isset($_POST['uuid']) && $oldUUID != $uuid) {
					$conflictUUID = $oldUUID;
				} else {
					$uuid = $oldUUID;
				}
			} 
		} else if ($row['uuid'] != "") {
			// If it has been found and it has a uuid, return this uuid
			$uuid = $row['uuid'];
		}
	} else {
		// If trip does not exist, create a new record
		$querySql = "INSERT INTO space_message (tripid, uuid, message) VALUES (" . $tripid . ", '" . $uuid . "', '" . $desiredaccuracy . "')" ;
	}
	
	// Insert or update the trip into the database
	if (!mysql_query($querySql,$con))
	{
		//echo $querySql;
		die('Error: ' . mysql_error());
		echo "Error updating message";
	}
	
	
	/// Get location data from database, create xml response and return it
	/// =============================
	
	
	echo "<?xml version='1.0' encoding='UTF-8'?><LocUpdate>"; 
	
	// Get location Data and process
	// ==================
	
	// prepare query
	$querySql = "SELECT * FROM space_coords WHERE ";
	$querySql .= " tripid=" . $tripid;
	$querySql .= " AND DATE_FORMAT(timestamp,  '%Y-%m-%d %h:%i:%s' )>= DATE_FORMAT('" . $lastTimestamp . "',  '%Y-%m-%d %h:%i:%s' )";
	$querySql .= " ORDER BY timestamp ASC";
	
	//Execute the query
	$show = mysql_query($querySql,$con) or die (mysql_error());
	
	// Loop through each row
	while ($row = mysql_fetch_array($show) ) {
		
		//get data from row
		$id = $row["id"];
		$longitude = $row["longitude"];
		$latitude = $row["latitude"];
		$altitude = $row["altitude"];
		$accuracy = $row["accuracy"];
		$altitudeAccuracy = $row["altitudeAccuracy"];
		$heading = $row["heading"];
		$speed = $row["speed"];
		$timestamp = $row["timestamp"];
		$tripid = $row["tripid"];
		$appstate = $row["appstate"];
		$batlevel = $row["batlevel"];

		// Create locData element
		echo "<LocData id='" . $id ."'>";
		echo "<longitude>". $longitude ."</longitude>";
		echo "<latitude>". $latitude ."</latitude>";
		echo "<altitude>". $altitude ."</altitude>";
		echo "<horizontalAccuracy>". $accuracy ."</horizontalAccuracy>";
		echo "<verticalAccuracy>". $altitudeAccuracy ."</verticalAccuracy>";
		echo "<course>". $heading ."</course>";
		echo "<speed>". $speed ."</speed>";
		echo "<theTimestamp>". $timestamp ."</theTimestamp>";
		echo "<tripid>". $tripid ."</tripid>";
		echo "<appstate>". $appstate ."</appstate>";
		echo "<batlevel>". $batlevel ."</batlevel>";
		echo "</LocData>";
	}
	
	// close the connection
	mysql_close($con);
	
	
	// Get current wind conditions
	$latitude = $latitude * 1000000;
	$longitude = $longitude * 1000000;
	
	$requestAddress = "http://www.google.com/ig/api?weather=,,," . $latitude . "," . $longitude;
	// Downloads weather data based on location - I used my zip code.
	$xml_str = file_get_contents($requestAddress,0);
	// Parses XML 
	$xml = new SimplexmlElement($xml_str);
	// Loops XML
	$count = 0;
	//echo '<weather>';
	foreach($xml->weather as $item) {
		foreach($item->current_conditions as $new) {
			echo '<wind>' . $new->wind_condition['data'] . '</wind>';
		}
	}
	
	
	// Get prediction data and process
	// ==================
	
	// If we were sent a UUID, there is no conflicting UUID in the database, and we definitely want the prediction returned... return it
	if ($uuid != "" && $conflictUUID == "" && $sendPred ==1) {
		
		// Check progress of prediction
		$tryProgress = "predictor/preds/". $uuid . "/progress.json";
		if(file_exists($tryProgress)) {
			$progresString = file_get_contents($tryProgress);
			$progress = json_decode($progresString);
			if ($progress->{'error'} && $progress->{'error'} != "{" && $progress->{'error'} != "" && $progress->{'error'} != null) {
				echo '<predMessage>There was an error in running the prediction: ' . $progress->{'error'} . '</predMessage>';
			} else {
				
		        // get the progress of the wind data
		        if ( $progress->{'gfs_complete'} == true ) {
		        	if ( $progress->{'pred_complete'} == true ) { // pred has finished
		                echo '<predMessage>Prediction finished.</predMessage>';
		                
		                // Get the CSV File
		                $tryfile = "predictor/preds/" . $uuid . "/flight_path.csv";
					    if(file_exists($tryfile)) {
						    $fh = fopen($tryfile, "r");
						    $data = array();
						    while (!feof($fh)) {
						        $line = trim(fgets($fh));
						        array_push($data, $line);
						    }
						    $returned = json_encode($data);
						    
						    if ($returned) {
						    	// Send the predition data
						    	echo '<predData>'. $returned . '</predData>';
						    }
					    }
			        } else if ( $progress->{'pred_running'} != true ) {
			                echo '<predMessage>Waiting for predictor to run...</predMessage>';
		            } else if ( $progress->{'pred_running'} == true ) {
		                echo '<predMessage>Predictor running...</predMessage>';
		            }
	            } else {
	            	echo '<predMessage>downloaded ' . $progress->{'gfs_percent'} . '% of GFS files</predMessage>';
	        	}
			}
		} else {
			echo '<predMessage>Cannot find progress.json</predMessage>';
		}
	} else if ($conflictUUID != "") {
		// If there is a conflict uuid, send that so that the user can decide what to do with it.
		echo '<predMessage>conflictUUID=' . $conflictUUID . '</predMessage>';
	}
	
	echo "</LocUpdate>";
?>