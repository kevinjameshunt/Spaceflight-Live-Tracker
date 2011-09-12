/*
 * Near Space Balloon Tracker V 1.0
 * Kevin James Hunt 2011
 * kevinjameshunt@gmail.com
 * http://www.kevinjameshunt.com
 *
 * http://github.com/kevinjameshunt/near-space-balloon-tracker
 *
 * Displays live balloon location and prediction data on flightmap.php
 *
 * Prediction data adapted from CUSF Landing Prediction Version 2  by Jon Sowman
 * http://github.com/jonsowman/cusf-standalone-predictor
 *
 */

var track_img = "images/target-11-sm.png";
var last_img = "images/target-13-sm.png";
var stateArray = new Array("Heading Up", "Above Towers", "Heading Down");
stateArray[10] = "Find Me!";
var lastTripID = 0;
var latestTimestamp = "";
var latestAppstate = "";
var markerCount = 0;
var the_current_uuid;

// UI messages for when tracker sends command to transmitter
var tripMessageArray = {"bestfornav":"We requested 'Best for Navigation' accuracy from the balloon", "best":"We requested 'Best' accuracy", "nearest10":"We requested 'Nearest 10m' accuracy", "significant":"We requested the balloon only transmit on significant updates only"}; 

// This function runs when the document object model is fully populated
// and the page is loaded
$(document).ready(function() {
    // Initialise the map canvas with parameters (lat, long, zoom-level)
    initMap(43, -79, 8);

    // Setup all event handlers in the UI using jQuery
    setupEventHandlers();

    // Initialise UI elements such as draggable windows
    initUI();
    
    // Check if an old prediction is to be displayed, and process if so
    displayLatest();
});

// Get lastest tripid, display actual location coords and prediction
function displayLatest() {
    $.get("map-ajax.php", { "action":"getTripData", "latestmessage":"Success"}, function(dataObj) {
		// convert received string to JSON object
		var JSONobject = JSON.parse(dataObj);

		// Get properties from JSON object
	   	var tripData = JSONobject.tripData;
	   	var tripMessage = tripData.message;
	   	lastTripID = tripData.tripid;
	   	the_current_uuid = tripData.uuid;
	   	var latest_TripMessage = tripData.latestMessage;
	   	
		// did server return a uuid?
		if(the_current_uuid != "") {
			// Display the prediction
			appendMessage("Displaying Prediction: " +the_current_uuid);
			appendMessage("Trying to get progress JSON");
			// Check to see if file exists (it may have been removed from system or not been created at all)
			$.ajax({
			    url:"preds/"+the_current_uuid+"/progress.json",
			    type:'HEAD',
			    error: function()
			    {
			        //file does not exist in preds directory, check in long-term directory
			        appendMessage("Trying to get progress JSON from long-term storage");
			        $.getJSON("predstore/"+the_current_uuid+"/progress.json", 
					   function(progress) {
					       if ( progress['error'] || !progress['pred_complete'] ) {
					           appendMessage("The prediction was not completed"
					               + " correctly, cannot display yet.");
					               ajaxEventHandle = setInterval("getJSONProgress('" 
		            + the_current_uuid + "')", stdPeriod);
					       } else {
					           getCSVLongTerm(the_current_uuid);
					       }
					   		
					   }
					);
			    },
			    success: function()
			    {
			        //file exists get prediction status
			        $.getJSON("preds/"+the_current_uuid+"/progress.json", 
					   function(progress) {
					       if ( progress['error'] || !progress['pred_complete'] ) {
					           appendMessage("The prediction was not completed"
					               + " correctly, cannot display yet.");
					               ajaxEventHandle = setInterval("getJSONProgress('" 
		            + the_current_uuid + "')", stdPeriod);
					       } else {
					           writePredictionInfo(the_current_uuid, 
					               progress['run_time'], 
					               progress['gfs_timestamp']);
					           getCSV(the_current_uuid);
					       }
					   		
					   }
					);
			    }
			});
			
		}
		
		// If there is existing balloon data
		if (JSONobject.markers.length > 0) {
			appendMessage("Loading data so far...");
			
			// Create the balloon markers
			createBalloonMarkers(JSONobject);
		}

		// If the balloon hasn't been found yet
		if (tripMessage != "Found") {
			// Set it's last message
			if (tripMessage != "Success") {
				appendMessage(tripMessageArray[tripMessage]);
				latest_TripMessage = "" + tripMessage;
			}
			// Set timer to update with new location data
    		ajaxEventHandle = setInterval(function() {updateTripData(latest_TripMessage);}, stdPeriod);
		} else {
			appendMessage("Balloon capsule found!  Videos will be posted <a href='http://kevinjameshunt.com'>HERE</a>"); 
		}
    });
}

// Update map with latest location data
function updateTripData(latest_TripMessage) {
	
	// Get data from db
	$.get("map-ajax.php", { "action":"getTripData", "timestamp":latestTimestamp, "latestmessage":latest_TripMessage}, function(dataObj) {
		
		clearInterval(ajaxEventHandle);
		
		// convert received string to JSON object
		var JSONobject = JSON.parse(dataObj);
		
		var tripData = JSONobject.tripData;
		var tripMessage = tripData.message;
		var latest_TripMessage = tripData.latestMessage;
		
		// If we are still using the same tripid
	   	if (lastTripID == tripData.tripid) {
			if (JSONobject) {
				map_items['last_marker'].setMap(null);
				
				//appendMessage("Retrieved latest balloon data.");
				// Create the balloon markers
				createBalloonMarkers(JSONobject);
				
				if (tripMessage != "Found") {
					if (tripMessage != "Success" && latest_TripMessage != tripMessage) {
						appendMessage(tripMessageArray[tripMessage]);
						latest_TripMessage = "" + tripMessage;
					}
				} else {
					if (latest_TripMessage != "Found") {
						appendMessage("Balloon capsule found!  Videos will be posted <a href='http://kevinjameshunt.com'>HERE</a>");
						latest_TripMessage = "" + tripMessage; 
					}
				}
	   	
				// did server return a uuid?
				if(the_current_uuid == "" && tripData.uuid != "") {
					// Check for prediction
					the_current_uuid = tripData.uuid;
					
					// Display the prediction
					appendMessage("Displaying Prediction: " +the_current_uuid);
					appendMessage("Trying to get progress JSON");
					$.getJSON("preds/"+the_current_uuid+"/progress.json", 
					   function(progress) {
					       if ( progress['error'] || !progress['pred_complete'] ) {
					           appendMessage("The prediction was not completed"
					               + " correctly, cannot display yet.");
					               ajaxEventHandle = setInterval("getJSONProgress('" 
		            + the_current_uuid + "')", stdPeriod);
					       } else {
					           writePredictionInfo(the_current_uuid, 
					               progress['run_time'], 
					               progress['gfs_timestamp']);
					           getCSV(the_current_uuid);
					       }
					   }
					);
				}
				// Set timer to check for updates again
				ajaxEventHandle = setInterval(function() {updateTripData(latest_TripMessage);}, stdPeriod);
			}
	   	} else {
	   		// A new trip has been started.  
	   		appendMessage("A new trip has been started.  Clearing the map.");
	   		
	   		// Reset values
	   		clearInterval(ajaxEventHandle);
	   		the_current_uuid = "";
	   		var latestTimestamp = "";
			var latestAppstate = "";
			var markerCount = 0;
			var latest_TripMessage = "";
	   		
	   		//Clear the map.
	   		clearMapItems();
	   		
	   		// Reset the trip data displayed
	   		displayLatest();
	   	}
	});
}


function createBalloonMarkers(JSONobject) {
	
	// Get properties from JSON object
   	var tripData = JSONobject.tripData;
   	var markers = JSONobject.markers;
   	
   	var tripMessage = tripData.message;
	
	// If markers from the actual balloon exist, display them
	if (markers && markers.length > 0) {
		
		// Display all but the very last one.
		for (var i = 0; i < markers.length-1; i++) {
			var timestamp = markers[i].timestamp;
			var state = markers[i].state;
			var bat = markers[i].bat;
			var lat = markers[i].lat;
			var lon = markers[i].lon;
			
			if (latestAppstate != state) {
				appendMessage("Balloon: " + stateArray[state]);
				latestAppstate = state;
			}
			
			var point = new google.maps.LatLng( parseFloat(lat), parseFloat(lon));
			
			// Create icon
			var balloon_icon = new google.maps.MarkerImage(track_img,
		        new google.maps.Size(16,16),
		        new google.maps.Point(0, 0),
		        new google.maps.Point(8, 8)
		    );
		      
		    // Create marker
		    var baloon_marker = new google.maps.Marker({
		        position: point,
		        map: map,
		        icon: balloon_icon,
		        title: "" + timestamp + " state: " + stateArray[state] + " battery: " + bat + "%"
		    });
		    
		    // Add to map items
		    map_items['baloon_marker_' + markerCount] = baloon_marker;
		    markerCount ++;
		}
	
		// Construct the last timestamp 
		var lastTimestamp = markers[markers.length-1].timestamp;
		var lastState = markers[markers.length-1].state;
		var lastBat = markers[markers.length-1].bat;
		var lastLat = markers[markers.length-1].lat;
		var lastLon = markers[markers.length-1].lon;
		
		latestTimestamp = lastTimestamp;
		
		if (tripMessage != "Found") {
			tripMessage = stateArray[lastState];
			if (latestAppstate != lastState) {
				appendMessage("Balloon: " + tripMessage);
				latestAppstate = lastState;
			}
		}
		
		var lastPoint = new google.maps.LatLng( parseFloat(lastLat), parseFloat(lastLon));
		
		// Create icon
		var last_icon = new google.maps.MarkerImage(last_img,
	        new google.maps.Size(16,16),
	        new google.maps.Point(0, 0),
	        new google.maps.Point(8, 8)
	    );
	      
	    // Create marker
	    var last_marker = new google.maps.Marker({
	        position: lastPoint,
	        map: map,
	        icon: last_icon,
	        title: "" + lastTimestamp + " state: " + tripMessage + " battery: " + lastBat + "%"
	    });
	    
	    // Add to map items
    	map_items['last_marker'] = last_marker;
    	
	}
}



// Populate and enable the download CSV, KML and Pan To links, and write the 
// time the prediction was run and the model used to the Scenario Info window
function writePredictionInfo(current_uuid, run_time, gfs_timestamp) {
    // populate the download links
    $("#dlcsv").attr("href", "preds/"+current_uuid+"/flight_path.csv");
    $("#dlkml").attr("href", "kml.php?uuid="+current_uuid);
    $("#panto").click(function() {
            map.panTo(map_items['launch_marker'].position);
            //map.setZoom(7);
    });
    $("#run_time").html(POSIXtoHM(run_time, "H:i d/m/Y"));
    $("#gfs_timestamp").html(gfs_timestamp);
}

// Hide the launch card and scenario information windows, then fade out the
// map before setting an interval to poll for prediction progress
function handlePred(pred_uuid) {
    $("#prediction_status").html("Searching for wind data...");
    $("#input_form").hide("slide", { direction: "down" }, 500);
    $("#scenario_info").hide("slide", { direction: "up" }, 500);
    // disable user control of the map canvas
    $("#map_canvas").fadeTo(1000, 0.2);
    // ajax to poll for progress
    ajaxEventHandle = setInterval("getJSONProgress('" 
            + pred_uuid + "')", stdPeriod);
}

// Get the CSV for a UUID and then pass it to the parseCSV() function
function getCSV(pred_uuid) {
    $.get("ajax.php", { "action":"getCSV", "uuid":pred_uuid }, function(data) {
            if(data != null) {
                if (parseCSV(data) ) {
                } else {
                    appendMessage("The parsing function failed.");
                }
            } else {
                appendMessage("Server couldn't find a CSV for that UUID");
                throwError("Sorry, we couldn't find the data for that UUID. "+
                    "Please run another prediction.");
            }
    }, 'json');
}

// Get the CSV for a UUID and then pass it to the parseCSV() function
function getCSVLongTerm(pred_uuid) {
    $.get("map-ajax.php", { "action":"getCSVLongTerm", "uuid":pred_uuid }, function(data) {
            if(data != null) {
                if (parseCSV(data) ) {
                } else {
                    appendMessage("The parsing function failed.");
                }
            } else {
                appendMessage("Server couldn't find a CSV for that UUID anywhere");
                throwError("Sorry, we couldn't find the data for that UUID. "+
                    "Please run another prediction.");
            }
    }, 'json');
}

// Called at set inervals to examine the progress.json file on the server for
// a UUID to check for progress, and update the progress window
// Also handles high latency connections by increasing the timeout before
// the AJAX request completes and decreasing polling interval
function getJSONProgress(pred_uuid) {
    $.ajax({
        url:"preds/"+pred_uuid+"/progress.json",
        dataType:'json',
        timeout: ajaxTimeout,
        error: function(xhr, status, error) {
            if ( status == "timeout" ) {
                appendMessage("Polling for progress JSON timed out");
                // check that we haven't reached maximum allowed timeout
                if ( ajaxTimeout < maxAjaxTimeout ) {
                    // if not, add the delta to the timeout value
                    newTimeout = ajaxTimeout + deltaAjaxTimeout;
                    appendMessage("Increasing AJAX timeout from " + ajaxTimeout
                        + "ms to " + newTimeout + "ms");
                    ajaxTimeout = newTimeout;
                } else if ( ajaxTimeout != hlTimeout ) {
                    // otherwise, increase poll delay and timeout
                    appendMessage("Reached maximum ajaxTimeout value of " 
                        + maxAjaxTimeout);
                    clearInterval(ajaxEventHandle);
                    appendMessage("Switching to high latency mode");
                    appendMessage("Setting polling interval to "+hlPeriod+"ms");
                    appendMessage("Setting progress JSON timeout to " 
                            + hlTimeout + "ms");
                    ajaxTimeout = hlTimeout;
                    ajaxEventHandle = setInterval("getJSONProgress('"
                             + pred_uuid + "')", hlPeriod);
                }
            }
        },
        success: processProgress
    });
}

// The contents of progress.json are given to this function to process
// If the prediction has completed, reset the GUI and display the new
// prediction; otherwise update the progress window
function processProgress(progress) {
    if ( progress['error'] ) {
        clearInterval(ajaxEventHandle);
        appendMessage("There was an error in running the prediction: " 
                + progress['error']);
    } else {
        // get the progress of the wind data
        if ( progress['gfs_complete'] == true ) {
            if ( progress['pred_complete'] == true ) { // pred has finished
                $("#prediction_status").html("Prediction finished.");
                appendMessage("Server says: the predictor finished running.");
                appendMessage("Attempting to retrieve flight path from server");
                // reset the GUI
                resetGUI();
                // stop polling for JSON
                clearInterval(ajaxEventHandle);
                // parse the data
                getCSV(current_uuid);
                appendMessage("Server gave a prediction run timestamp of " 
                        + progress['run_time']);
                appendMessage("Server said it used the " 
                        + progress['gfs_timestamp'] + " GFS model");
                writePredictionInfo(current_uuid, progress['run_time'], 
                        progress['gfs_timestamp']);
            } else if ( progress['pred_running'] != true ) {
                $("#prediction_status").html("Waiting for predictor to run...");
                appendMessage("Server says: predictor not yet running...");
            } else if ( progress['pred_running'] == true ) {
                $("#prediction_status").html("Predictor running...");
                appendMessage("Server says: predictor currently running");
            }
        } else {
            $("#prediction_status").html("Downloading wind data");
            $("#prediction_progress").progressbar("option", "value",
                progress['gfs_percent']);
            $("#prediction_percent").html(progress['gfs_percent'] + 
                "% - Estimated time remaining: " 
                + progress['gfs_timeremaining']);
            appendMessage("Server says: downloaded " +
                progress['gfs_percent'] + "% of GFS files");
        }
    }
    return true;
}

// Once a flight path has been returned from the server, this function takes
// an array where each elemt is a line of that file
// Constructs the path, plots the launch/land/burst markers, writes the
// prediction information to the scenario information window and then plots
// the delta square
function parseCSV(lines) {
    if( lines.length <= 0 ) {
        appendMessage("The server returned an empty CSV file");
        return false;
    }
    var path = [];
    var max_height = -10; //just any -ve number
    var max_point = null;
    var launch_lat;
    var launch_lon;
    var land_lat;
    var land_lon;
    var launch_pt;
    var land_pt;
    var burst_lat;
    var burst_lon;
    var burst_pt;
    var burst_time;
    var launch_time;
    var land_time;
    $.each(lines, function(idx, line) {
        entry = line.split(',');
        // Check for a valid entry length
        if(entry.length >= 4) {
            var point = new google.maps.LatLng( parseFloat(entry[1]), 
                parseFloat(entry[2]) );
            // Get launch lat/lon
            if ( idx == 0 ) {
                launch_lat = entry[1];
                launch_lon = entry[2];
                launch_time = entry[0];
                launch_pt = point;
            }

            // Set on every iteration such that last valid entry gives the
            // landing position
            land_lat = entry[1];
            land_lon = entry[2];
            land_time = entry[0];
            land_pt = point;
            
            // Find the burst lat/lon/alt
            if( parseFloat(entry[3]) > max_height ) {
                max_height = parseFloat(entry[3]);
                burst_pt = point;
                burst_lat = entry[1];
                burst_lon = entry[2];
                burst_time = entry[0];
            }

            // Push the point onto the polyline path
            path.push(point);
        }
    });

    appendMessage("Server: prediction data parsed, creating map plot.");
    //clearMapItems();
    
    // Calculate range and time of flight
    var range = distHaversine(launch_pt, land_pt, 1);
    var flighttime = land_time - launch_time;
    var f_hours = Math.floor((flighttime % 86400) / 3600);
    var f_minutes = Math.floor(((flighttime % 86400) % 3600) / 60);
    if ( f_minutes < 10 ) f_minutes = "0"+f_minutes;
    flighttime = f_hours + "hr" + f_minutes;
    $("#cursor_pred_range").html(range);
    $("#cursor_pred_time").html(flighttime);
    $("#cursor_pred").show();
    
    // Make some nice icons
    var launch_icon = new google.maps.MarkerImage(launch_img,
        new google.maps.Size(16,16),
        new google.maps.Point(0, 0),
        new google.maps.Point(8, 8)
    );
    
    var land_icon = new google.maps.MarkerImage(land_img,
        new google.maps.Size(16,16),
        new google.maps.Point(0, 0),
        new google.maps.Point(8, 8)
    );
      
    var launch_marker = new google.maps.Marker({
        position: launch_pt,
        map: map,
        icon: launch_icon,
        title: 'Balloon launch ('+launch_lat+', '+launch_lon+') at ' 
            + POSIXtoHM(launch_time) + "UTC"
    });

    var land_marker = new google.maps.Marker({
        position: land_pt,
        map:map,
        icon: land_icon,
        title: 'Predicted Landing ('+land_lat+', '+land_lon+') at ' 
            + POSIXtoHM(land_time) + "UTC"
    });

    var path_polyline = new google.maps.Polyline({
        path:path,
        map: map,
        strokeColor: '#000000',
        strokeWeight: 3,
        strokeOpacity: 0.75
    });

    var pop_marker = new google.maps.Marker({
            position: burst_pt,
            map: map,
            icon: burst_img,
            title: 'Balloon burst (' + burst_lat + ', ' + burst_lon 
                + ' at altitude ' + max_height + 'm) at ' 
                + POSIXtoHM(burst_time) + "UTC"
    });

    // Add the launch/land markers to map
    // We might need access to these later, so push them associatively
    map_items['launch_marker'] = launch_marker;
    map_items['land_marker'] = land_marker;
    map_items['pop_marker'] = pop_marker;
    map_items['path_polyline'] = path_polyline;

    // We wiped off the old delta square,
    // And it may have changed anyway, so re-plot
    drawDeltaSquare(map);
    
    // Pan to the new position
    map.panTo(launch_pt);
    map.setZoom(8);

    return true;
}

// Return the size of a given associative array
function getAssocSize(arr) {
    var i = 0;
    for ( j in arr ) {
        i++;
    }
    return i;
}

function POSIXtoHM(timestamp, format) {
    // using JS port of PHP's date()
    var ts = new Date();
    ts.setTime(timestamp*1000);
    // account for DST
    if ( ts.format("I") ==  1 ) {
        ts.setTime((timestamp-3600)*1000);
    }
    if ( format == null || format == "" ) format = "H:i";
    var str = ts.format(format);
    return str;
}

rad = function(x) {return x*Math.PI/180;}

// Append a line to the debug window and scroll the window to the bottom
// Optional boolean second argument will clear the debug window if TRUE
function appendMessage(appendage, clear) {
    if ( clear == null ){
        var curr = $("#messageinfo").html();
        curr += "<br>" + appendage;
        $("#messageinfo").html(curr);
    } else {
        $("#messageinfo").html("");
    }
    // keep the debug window scrolled to bottom
    scrollToBottom("message_window");
}
