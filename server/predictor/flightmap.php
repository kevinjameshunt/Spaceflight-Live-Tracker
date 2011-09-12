<?php

/*
 * Near Space Balloon Tracker V 1.0
 * Kevin James Hunt 2011
 * kevinjameshunt@gmail.com
 * http://www.kevinjameshunt.com
 *
 * http://github.com/kevinjameshunt/near-space-balloon-tracker
 *
 * Front-end Web Interface for observing balloon flight in progress (or last experiment).
 *
 * Interface and Prediction data adapted from CUSF Landing Prediction Version 2  by Jon Sowman
 * http://github.com/jonsowman/cusf-standalone-predictor
 *
 */

require_once("includes/config.inc.php");
require_once("includes/functions.inc.php");

// Get the time for pre-populating the form
$time = time() + 3600;
?>
<html>
<head>
<title>Balloon Flight Map</title>
<meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
<script type="text/javascript" src="http://www.google.com/jsapi?key=<?php echo GMAPS_API_KEY; ?>">
</script>
<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
<link href="css/pred.css" type="text/css" rel="stylesheet" />
<link href="map_includes/flightmap.css" type="text/css" rel="stylesheet" />
<link href="css/calc.css" type="text/css" rel="stylesheet" />
<link rel="stylesheet" href="css/tipsy.css" type="text/css" />
<link href="css/cupertino/jquery-ui-1.8.1.custom.css" type="text/css" rel="stylesheet">
<script type="text/javascript">
// Load jquery and jqueryui before loading jquery.form.js later
google.load("jquery", "1.4.2");
google.load("jqueryui", "1.8.1");
</script>
<script src="js/jquery/jquery.form.js" type="text/javascript"></script>
<script src="js/jquery/jquery.jookie.js" type="text/javascript"></script>
<script src="js/jquery/jquery.tipsy.js" type="text/javascript"></script>
<script src="js/utils/date.jsport.js" type="text/javascript"></script>

<script src="js/pred/pred-config.js" type="text/javascript"></script>
<script src="js/pred/pred-ui.js" type="text/javascript"></script>
<script src="js/pred/pred-cookie.js" type="text/javascript"></script>
<script src="js/pred/pred-map.js" type="text/javascript"></script>
<script src="js/pred/pred-event.js" type="text/javascript"></script>
<script src="js/calc/calc.js" type="text/javascript"></script>

<script src="map_includes/map-pred.js" type="text/javascript"></script>

</head>
<body>

<!-- Map canvas -->
<div id="map_canvas"></div>

<!-- Debug window -->
<div id="message_window" class="box ui-corner-all">
<h1>Message Window</h1>
<span id="messageinfo">No Messages</span>
</div>

<div id="scenario_template"></div>

<!-- Scenario information -->
<div id="scenario_info" class="box ui-corner-all">
    <img src="images/drag_handle.png" class="handle" />
    <h1>Prediction Information</h1>
    You are viewing the data from our latest near-space balloon launch.  Check out the <a href="http://kevinjameshunt.com/category/near-space-balloon/">news feed</a> for more info, photos, etc.<br /><br /> 
    The blue dots represent the actual location data returned by the balloon.  The solid line represents the predicted flight path.<br />
    <span id="cursor_info">Current mouse position: 
        Lat: <span id="cursor_lat">?</span> 
        Lon: <span id="cursor_lon">?</span>
    </span><br />
    <span id="cursor_pred" style="display:none">
        Range: <span id="cursor_pred_range"></span>km, 
        Flight Time: <span id="cursor_pred_time"></span><br />
        Cursor range from launch: <span id="cursor_pred_launchrange">?</span>km, 
        land: <span id="cursor_pred_landrange">?</span>km
        <br />
        Last run at <span id="run_time">?</span> UTC using model <span id="gfs_timestamp">?</span>
        <br />
        <span class="ui-corner-all control_buttons">
            <a class="control_button" id="panto">Pan To</a> | 
            <a class="control_button" id="dlcsv">CSV</a> | 
            <a class="control_button" id="dlkml">KML</a>
        </span>
    </span>
    <br />
    <span class="ui-corner-all control_buttons">
        <a class="control_button" id="about_window_show">About</a>
    </span>
</div>

<!-- About window -->
<div id="about_window">
    <b>Spaceflight Live Tracker and Prediction Comparison</b>
    <br /><br />
    This tracks the flight high altitude "near space" balloons.  The data being displayed is from the latest flight of one of our balloons.  If you have found one of our balloon capsules please call 647-867-0768 or 1-213-784-0957.  There is a <b>cash reward</b>.
    <br /><br />
    Prediction data generated using the <a href="http://www.cuspaceflight.co.uk" target="_blank">CUSF Landing Prediction Predictor</a>.  For more information, see #highaltitude on irc.freenode.net.
</div>

</body>
</html>
