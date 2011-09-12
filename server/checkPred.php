<?php

/*
 * Near Space Balloon Tracker V 1.0
 * Kevin James Hunt 2011
 * kevinjameshunt@gmail.com
 * http://www.kevinjameshunt.com
 *
 * http://github.com/kevinjameshunt/near-space-balloon-tracker
 *
 * Checks progress of prediction and returns it as XML
 *
 * Prediction data adapted from CUSF Landing Prediction Version 2  by Jon Sowman
 * http://github.com/jonsowman/cusf-standalone-predictor
 *
 */

	// Create XML document containing status of prediction
	echo "<?xml version='1.0' encoding='UTF-8'?><PredUpdate>";

	if (isset($_POST['uuid'])) {
		$uuid = $_POST['uuid'];
		
		// Check progress of prediction
		$tryProgress = "predictor/preds/". $uuid . "/progress.json";
		if(file_exists($tryProgress)) {
			$progresString = file_get_contents($tryProgress);
			$progress = json_decode($progresString);
			if ($progress->{'error'} && $progress->{'error'} != "" && $progress->{'error'} != null) {
				echo '<predMessage>There was an error in running the prediction: ' . $progress->{'error'} . '</predMessage>';
			} else {
		        // get the progress of the wind data
		        if ( $progress->{'gfs_complete'} == true ) {
		        	if ( $progress->{'pred_complete'} == true ) { // pred has finished
		                echo '<predMessage>Prediction finished.</predMessage>';
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
	}
	echo "</PredUpdate>";
?>