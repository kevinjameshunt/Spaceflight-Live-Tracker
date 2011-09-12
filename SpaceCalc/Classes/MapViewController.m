//
//  MapViewController.m
//  SpaceCalc 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import "MapViewController.h"
#import "SpaceCalcAppDelegate.h"
#import "LocXMLParser.h"

#define kHEADING_UP 0
#define kABOVE_TOWERS 1
#define kHEADING_DOWN 2
#define kFIND_ME 10
#define kDistanceFiler 20 // metres

@implementation LocationAnnotation

@synthesize coordinate, mSubTitle, mTitle, theLocation;

- (NSString *)subtitle{
	return mSubTitle;
}

- (NSString *)title{
	return mTitle;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D) c{
	coordinate=c;
	return self;
}

@end




@implementation MapViewController

@synthesize mapView, scAppDel, accuracyButton, pollButton, refreshButton, launchButton, updateTimer, tripid, pickerViewArray, accuracyPickerView, navBar, containerView, toolbar, spinner;
@synthesize startLocation, aLocation, endLocation, userLocAnnotation, landingLocAnnotation, lastLocAnnotation, routeAnnotation, theRouteView, foundLocations, userLocation, locationManager, locationAccuracy, lastTimestamp, launchTimestamp, desiredAccuracy, conflictUUID, isPolling, tripidUpdated, replaceUUID;
@synthesize contentView = _contentView;


#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
	
	//Get Location data
	scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	foundLocations = [[NSMutableArray alloc] init];
    self.isPolling = NO;
    self.launchTimestamp = nil;
    self.desiredAccuracy = @"Success";
	
    // set default values
	[self restoreDefaults];
    
	NSInteger tripNo = [[NSUserDefaults standardUserDefaults] integerForKey:@"tripid"];
	if (tripNo > 0) {
		tripid.text = [NSString stringWithFormat:@"%d", (tripNo+1)];
	} else {
		tripid.text = [NSString stringWithFormat:@"%d", 0];
	}
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	//[self performSelectorOnMainThread:@selector(setupMapView) withObject:nil waitUntilDone:YES];
}

#pragma mark -
#pragma mark User Functions

-(void) restoreDefaults {
    foundLocations = [[NSMutableArray alloc] init];
	self.locationAccuracy = kCLLocationAccuracyBest;
    self.tripidUpdated = YES;
    self.lastTimestamp = @"2010-01-01 11:11:11";
}

/**
 Register that the balloon has launched and record the time
 */
- (IBAction) launchBtnPressed {
    self.launchButton.enabled = NO;
    
    // Record launch time and store it with tripid
    NSDate *currentDateTime = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:currentDateTime forKey:[NSString stringWithFormat:@"launch-timestamp-%@",self.tripid.text]];
    
    // Format date string
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:currentDateTime];
    self.launchTimestamp = dateString;
    
    DebugLog(@"Recorded Launch Date & Time: %@",dateString);
    
    [dateFormatter release];
}

/**
 Start or pause polling for location and prediction data
 */
- (IBAction) startPolling {
    
    // Pause
	if (self.isPolling) {
		self.isPolling = NO;
        self.tripidUpdated = NO;
		self.pollButton.title = @"Resume";
        tripid.enabled = YES;
		[self.updateTimer invalidate];
		[[self locationManager] stopUpdatingLocation];
	} else {
    // Start / Resume / Restart
        self.isPolling = YES;
		tripid.enabled = NO;
		self.pollButton.title = @"Pause";
		
        // Start the location manager.
        [[self locationManager] startUpdatingLocation];
        
        // If the user has changed the tripid, refresh the map
        if (tripidUpdated) {
            launchButton.enabled = YES;
            launchTimestamp = nil;
            tripidUpdated = NO;
            scAppDel.predComplete = NO;
            scAppDel.mapPoints = nil;

            [[NSUserDefaults standardUserDefaults] setObject:tripid.text forKey:@"tripid"];
            
            [self.spinner startAnimating];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            [self performSelectorInBackground:@selector(refreshMapView) withObject:nil];

            [[NSUserDefaults standardUserDefaults] synchronize];
        } 
        
        // Set update timer
        [self setUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(updateMapView) userInfo:nil repeats:YES]];
	}
}

/**
 Poll server for location data
 */
- (void) searchDb {
	
    NSString *serverUrl = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverUrl"];

    //Generate search url
	NSString *siteName = [[NSString alloc] initWithFormat:@"%@/getLoc.php", serverUrl];
	NSString *urlString = [[NSString alloc] initWithString:@"lastTimestamp="];
	urlString = [urlString stringByAppendingString:[self.lastTimestamp stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	urlString = [urlString stringByAppendingFormat:@"&tripid=%@",self.tripid.text];
    urlString = [urlString stringByAppendingFormat:@"&desiredaccuracy=%@",self.desiredAccuracy];
    
    // If we are replacing the old uuid
    if (self.replaceUUID) {
        urlString = [urlString stringByAppendingFormat:@"&uuid=%@",scAppDel.currentUUID];
        urlString = [urlString stringByAppendingString:@"&replaceUUID=1"];
        urlString = [urlString stringByAppendingString:@"&sendPred=1"];
        self.replaceUUID = NO;
    } else if (scAppDel.predComplete == NO && self.conflictUUID) {
        // we want the old uuid
        urlString = [urlString stringByAppendingFormat:@"&uuid=%@",conflictUUID];
        urlString = [urlString stringByAppendingString:@"&sendPred=1"];
    } else if (scAppDel.predComplete == NO && scAppDel.currentUUID) {
        // send the prediction for this uuid
        urlString = [urlString stringByAppendingFormat:@"&uuid=%@",scAppDel.currentUUID];
        urlString = [urlString stringByAppendingString:@"&sendPred=1"];
	} else if (scAppDel.predComplete == NO) {
        // send us whatever prediction is in the db
        urlString = [urlString stringByAppendingString:@"&sendPred=1"];
    }
        
	DebugLog(@"%@",urlString);
	
    // Creat the request
	NSData *myRequestData = [ NSData dataWithBytes: [ urlString UTF8String ] length: [ urlString length ] ];
	NSMutableURLRequest *request = [ [ NSMutableURLRequest alloc ] initWithURL: [ NSURL URLWithString:siteName ] ]; 
	[ request setHTTPMethod: @"POST" ];
	[ request setHTTPBody: myRequestData ];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	
	NSHTTPURLResponse* response = nil;  
	NSError* error = [[NSError alloc] init];  
	NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error ];
	
	// Display result in log
	NSString *result = [[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding];
	DebugLog(@"%@",result);
	
	//Load content.
	//NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:returnData];
	
	//Initialize the delegate.
	LocXMLParser *parser = [[LocXMLParser alloc] initXMLParser];
	
	//Set delegate
	[xmlParser setDelegate:parser];
	
	//Start parsing the XML file.
	BOOL success = [xmlParser parse];
	
    // The request was successful
	if(success) {
		UIAlertView *errorAlert = nil;
        self.scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
		DebugLog(@"No Parsing Errors");
        
        // Check predMessage
        NSRange uuidLoc = [scAppDel.lastPredMessage rangeOfString:@"conflictUUID="]; 
        
        // If there is a conflict ID, displace message asking user to choose
        if (uuidLoc.location != NSNotFound) {
            self.conflictUUID = [scAppDel.lastPredMessage substringFromIndex:uuidLoc.length];
            errorAlert = [[UIAlertView alloc]
                          initWithTitle: @"Existing Prediction Found"
                          message: @"The server already has prediction data associated with this trip.  Do you want to use the new prediction data (recommended) or load the old prediction."
                          delegate:self
                          cancelButtonTitle:@"Use Old"
                          otherButtonTitles:@"Use New",nil];
        } else if ([scAppDel.lastPredMessage isEqualToString:@"Cannot find progress.json"]) {
            // If we couldn't find the prediction at all, display an alert
            errorAlert = [[UIAlertView alloc]
                                       initWithTitle: @"Error: Could not find prediction"
                                       message: @"Could not find prediction data.  The prediction may have failed or been deleted from the server.  Please create a new one."
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
        } else if (![scAppDel.lastPredMessage isEqualToString:@"Prediction finished."] && ![scAppDel.lastPredMessage isEqualToString:@""]) {
            // Display error message as alert
            errorAlert = [[UIAlertView alloc]
                          initWithTitle: @"Prediction Server Says:"
                          message: scAppDel.lastPredMessage
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
        } 
        
        if (errorAlert) {
            [errorAlert show];
            [errorAlert release];
        }
	} else
		DebugLog(@"Error Error Error in Parsing!!!");
    
    [request release];
    [result release];
    [xmlParser release];
    [parser release];
}

/**
 Refresh the map manually
 */
- (IBAction) refreshBtnPressed {
    [self.spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self performSelectorInBackground:@selector(refreshMapView) withObject:nil];
}


/**
 Refresh the map
 */
- (void) refreshMapView {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    // Set dynamic map zoom
    MKCoordinateRegion region = mapView.region;
    MKCoordinateSpan span;
    if (self.locationAccuracy == kCLLocationAccuracyBestForNavigation){
        span.latitudeDelta=0.001;
        span.longitudeDelta=0.001;
        region.span=span;
    } else {
        span.latitudeDelta=1;
        span.longitudeDelta=1;
        region.span=span;
    }
    
    [self restoreDefaults];
    
    CLLocation *theLocation;
    LocationAnnotation *capAnnotation;
    
    // Receive data from transmitter through server
    scAppDel.foundLocations = [[NSMutableArray alloc] init];
    [self performSelectorOnMainThread:@selector(searchDb) withObject:nil waitUntilDone:YES];
    
    // Remove all annotations
    [mapView removeAnnotations:[mapView annotations]];
    
    // Get Locations from service
    foundLocations = scAppDel.foundLocations;
    
    // first create the route annotation, so it does not draw on top of the other annotations. 
    if (scAppDel.mapPoints && [scAppDel.mapPoints count] > 0) {
        
        // Add the route annotation
        self.routeAnnotation = [[CSRouteAnnotation alloc] initWithPoints:scAppDel.mapPoints];
        [mapView addAnnotation:self.routeAnnotation];
        
        // Create the estimated landing annotation
        theLocation = [scAppDel.mapPoints objectAtIndex:[scAppDel.mapPoints count]-1];
        landingLocAnnotation = [[LocationAnnotation alloc] initWithCoordinate:theLocation.coordinate];
        
        // We we have a launch timestamp
        if (self.launchTimestamp) {
            
            // Format approximate landing time
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *launchTime = [dateFormatter dateFromString:self.launchTimestamp];
            NSDate *landTime = [[NSDate alloc] initWithTimeInterval:scAppDel.flightTime sinceDate:launchTime];
            [dateFormatter setDateFormat:@"MM/dd/YY hh:mm a"];
            NSString *landTimetamp = [dateFormatter stringFromDate:landTime];
            landingLocAnnotation.mTitle = [NSString stringWithFormat:@"Approx: %@",landTimetamp];
            
            // Format estimated flight time
            int flightTimeMin = scAppDel.flightTime /60;           // minutes
            int hoursToBurst = (int)(flightTimeMin/60);           // hours
            int rminToBurst = (int)(flightTimeMin % 60);
            landingLocAnnotation.mSubTitle = [NSString stringWithFormat:@"Est. Flight Time: %d h, %d min", hoursToBurst, rminToBurst];
            
            [dateFormatter release];
            [landTime release];
        } else {
            // If not, just display the flight time
            int flightTimeMin = scAppDel.flightTime /60;           // minutes
            int hoursToBurst = (int)(flightTimeMin/60);           // hours
            int rminToBurst = (int)(flightTimeMin % 60);
            landingLocAnnotation.mTitle = [NSString stringWithFormat:@"Est. Flight Time: %d h, %d min", hoursToBurst, rminToBurst];
        }
        
        // Add the estimated landing location to map
        [mapView addAnnotation:self.landingLocAnnotation];
    }
    
    // cycle through and add all new Locations
    if ([foundLocations count] > 0)  {
        for (int i=0; i<[foundLocations count]; i++) {
            
            // Get the location and create pin for map
            aLocation = [foundLocations objectAtIndex:i];
            theLocation = [aLocation getLocation];
            
            // If the distance is greater than the filter value
            float distance = [theLocation distanceFromLocation:lastLocAnnotation.theLocation];
            if (distance > kDistanceFiler || distance == -1) {
                capAnnotation = [[LocationAnnotation alloc] initWithCoordinate:theLocation.coordinate];
                
                //calculate time of recording
                NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
                [outputFormatter setDateFormat:@"MM/dd/YY hh:mm a"];
                NSString *dateString = [outputFormatter stringFromDate:theLocation.timestamp];
                
                //Create status label
                NSString *balloonStatus = @"";
                if (aLocation.appstate == kHEADING_UP)
                    balloonStatus = @"Heading Up: ";
                else if (aLocation.appstate == kHEADING_DOWN)
                    balloonStatus = @"Heading Down: ";
                else if (aLocation.appstate == kABOVE_TOWERS)
                    balloonStatus = @"Above Towers: ";
                else if (aLocation.appstate == kFIND_ME)
                    balloonStatus = @"Find Me: ";
                
                //Set titles on pin
                capAnnotation.mTitle = [balloonStatus stringByAppendingString:dateString];
                
                // Last pin has special formatting
                if (i < [foundLocations count]-1) {
                    if (theLocation.verticalAccuracy > -1)
                        capAnnotation.mSubTitle = [NSString stringWithFormat:@"Alt: %.0f m. Bat: %.0f%%",theLocation.altitude, aLocation.batlevel];
                    else 
                        capAnnotation.mSubTitle = [NSString stringWithFormat:@"Bat: %.0f%%",aLocation.batlevel];
                    
                    // add pin to map
                    [mapView addAnnotation:capAnnotation];
                    
                } else {
                    // set it's titles below
                    lastLocAnnotation = capAnnotation;
                }
                
                [outputFormatter release];
            } 
            
        }
        
        // Create titles for final annotation
        lastLocAnnotation.mTitle = capAnnotation.mTitle;
        if (theLocation.verticalAccuracy > -1)
            lastLocAnnotation.mSubTitle = [NSString stringWithFormat:@"Alt: %.0f m. Bat: %.0f%% Wind: %.2f km/h %@",
                                           theLocation.altitude, aLocation.batlevel, [scAppDel.windSpeed floatValue], scAppDel.windDir];
        else
            lastLocAnnotation.mSubTitle = [NSString stringWithFormat:@"Bat: %.0f%% Wind: %.2f km/h %@", aLocation.batlevel, 
                                           [scAppDel.windSpeed doubleValue], scAppDel.windDir];
        
        // Add last annotation to map
        [mapView addAnnotation:lastLocAnnotation];
        
        // Update current user location on map with distance to last loaded location
        userLocAnnotation = mapView.userLocation;
        CLLocation *location = userLocAnnotation.location;
        float distance = [location distanceFromLocation:theLocation];
		userLocAnnotation.title = [NSString stringWithFormat:@"Distance: %.2f m",distance];
        if (theLocation.verticalAccuracy > -1)
            userLocAnnotation.subtitle = [NSString stringWithFormat:@"Altitude: %.2f m",location.altitude];
        
        // center map on last added pin
        region.center=theLocation.coordinate;
        
        // store last timestamp for next search
        self.lastTimestamp = aLocation.theTimestamp;
    } else {
        // center map on user
        userLocAnnotation = mapView.userLocation;
        userLocation = userLocAnnotation.location.coordinate;
        region.center=userLocation;
    }
    
    // Adjust region
    [mapView setRegion:region animated:TRUE];
    [mapView regionThatFits:region];
    
    [self.spinner stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [pool release];
}

/**
 Update the map with new location data
 */
- (void) updateMapView {
    [self.spinner startAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    // Set dynamic map zoom
    MKCoordinateRegion region = mapView.region;
    MKCoordinateSpan span;
    if (self.locationAccuracy == kCLLocationAccuracyBestForNavigation){
        span.latitudeDelta=0.001;
        span.longitudeDelta=0.001;
        region.span=span;
    } 
    
    LocationAnnotation *capAnnotation;
    CLLocation *theLocation;
    
    // Receive data from transmitter through server
    [self searchDb];
    
    // Get Locations from service
    NSMutableArray *newLocations = scAppDel.newLocations;
    
    // Remove last Location annotation from map
    if (lastLocAnnotation)
        [mapView removeAnnotation:lastLocAnnotation];
    
    // Remove predicted landing location from map
    if (landingLocAnnotation)
        [mapView removeAnnotation:landingLocAnnotation];
    
    // Remove the predicted route from the map
    if (routeAnnotation)
        [mapView removeAnnotation:routeAnnotation];
    
    // first create the route annotation, so it does not draw on top of the other annotations. 
    if (scAppDel.mapPoints && [scAppDel.mapPoints count] > 0) {
        
        // Add the route annotation
        self.routeAnnotation = [[CSRouteAnnotation alloc] initWithPoints:scAppDel.mapPoints];
        [mapView addAnnotation:self.routeAnnotation];
        
        // Create the estimated landing annotation
        theLocation = [scAppDel.mapPoints objectAtIndex:[scAppDel.mapPoints count]-1];
        landingLocAnnotation = [[LocationAnnotation alloc] initWithCoordinate:theLocation.coordinate];
        if (self.launchTimestamp) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            NSDate *launchTime = [dateFormatter dateFromString:self.launchTimestamp];
            NSDate *landTime = [[NSDate alloc] initWithTimeInterval:scAppDel.flightTime sinceDate:launchTime];
            [dateFormatter setDateFormat:@"MM/dd/YY hh:mm a"];
            NSString *landTimetamp = [dateFormatter stringFromDate:landTime];
            landingLocAnnotation.mTitle = [NSString stringWithFormat:@"Approx: %@",landTimetamp];
            
            int flightTimeMin = scAppDel.flightTime /60;           // minutes
            int hoursToBurst = (int)(flightTimeMin/60);           // hours
            int rminToBurst = (int)(flightTimeMin % 60);
            landingLocAnnotation.mSubTitle = [NSString stringWithFormat:@"Est. Flight Time: %d h, %d min", hoursToBurst, rminToBurst];
            
            [landTime release];
            [dateFormatter release];
        } else {
            int flightTimeMin = scAppDel.flightTime /60;           // minutes
            int hoursToBurst = (int)(flightTimeMin/60);           // hours
            int rminToBurst = (int)(flightTimeMin % 60);
            landingLocAnnotation.mTitle = [NSString stringWithFormat:@"Est. Flight Time: %d h, %d min", hoursToBurst, rminToBurst];
        }
        
        // Add the estimated landing location to map
        [mapView addAnnotation:self.landingLocAnnotation];
    }
    
    // cycle through and add all new Locations
    if ([newLocations count] > 0)  {
        for (int i=0; i<[newLocations count]; i++) {
            
            // Get the location and create pin for map
            aLocation = [newLocations objectAtIndex:i];
            theLocation = [aLocation getLocation];
            
            // If the distance is greater than the filter value
            float distance = [theLocation distanceFromLocation:lastLocAnnotation.theLocation];
            if (distance > kDistanceFiler || distance == -1) {
                capAnnotation = [[LocationAnnotation alloc] initWithCoordinate:theLocation.coordinate];
                
                //calculate time of recording
                NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
                [outputFormatter setDateFormat:@"MM/dd/YY hh:mm a"];
                NSString *dateString = [outputFormatter stringFromDate:theLocation.timestamp];
                
                //Create status label
                NSString *balloonStatus = @"";
                if (aLocation.appstate == kHEADING_UP)
                    balloonStatus = @"Heading Up: ";
                else if (aLocation.appstate == kHEADING_DOWN)
                    balloonStatus = @"Heading Down: ";
                else if (aLocation.appstate == kABOVE_TOWERS)
                    balloonStatus = @"Above Towers: ";
                else if (aLocation.appstate == kFIND_ME)
                    balloonStatus = @"Find Me: ";
                
                //Set titles on pin
                capAnnotation.mTitle = [balloonStatus stringByAppendingString:dateString];
                if (theLocation.verticalAccuracy > -1)
                    capAnnotation.mSubTitle = [NSString stringWithFormat:@"Alt: %.0f m. Bat: %.0f%%",theLocation.altitude, aLocation.batlevel];
                else 
                    capAnnotation.mSubTitle = [NSString stringWithFormat:@"Bat: %.0f%%",aLocation.batlevel];
                
                // add pin to map
                if (i < [foundLocations count]-1) {
                    [mapView addAnnotation:capAnnotation];
                } else {
                    lastLocAnnotation = capAnnotation;
                }
            } 
            
        }
        
        // Create titles for final annotation
        if (theLocation.verticalAccuracy > -1)
            lastLocAnnotation.mSubTitle = [NSString stringWithFormat:@"Alt: %.0f m. Bat: %.0f%% Wind: %.2f km/h %@",
                                           theLocation.altitude, aLocation.batlevel, [scAppDel.windSpeed floatValue], scAppDel.windDir];
        else
            lastLocAnnotation.mSubTitle = [NSString stringWithFormat:@"Bat: %.0f%% Wind: %.2f km/h %@", aLocation.batlevel, 
                                           [scAppDel.windSpeed doubleValue], scAppDel.windDir];
        
        // Add last annotation to map
        [mapView addAnnotation:lastLocAnnotation];
        
        // Update current user location on map with distance to last loaded location
        userLocAnnotation = mapView.userLocation;
        CLLocation *location = userLocAnnotation.location;
        float distance = [location distanceFromLocation:theLocation];
		userLocAnnotation.title = [NSString stringWithFormat:@"Distance: %.2f m",distance];
        if (theLocation.verticalAccuracy > -1)
            userLocAnnotation.subtitle = [NSString stringWithFormat:@"Altitude: %.2f m",location.altitude];
        
        // center map on last added pin
        region.center=theLocation.coordinate;
        
        // store last timestamp for next search
        self.lastTimestamp = aLocation.theTimestamp;
    } else {
        // center map on user
        userLocAnnotation = mapView.userLocation;
        userLocation = userLocAnnotation.location.coordinate;
        region.center=userLocation;
    }
    
    // Adjust region
    [mapView setRegion:region animated:TRUE];
    [mapView regionThatFits:region];
    
    [self.spinner stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark mapView delegate functions

/**
 Add annotation to map
 */
- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation{
    MKPinAnnotationView *annView=[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentloc"];
    annView.animatesDrop=NO;
    annView.canShowCallout = YES;
    //annView.calloutOffset = CGPointMake(-5, 5);
	
    // if it is the route annotation
	if([annotation isKindOfClass:[CSRouteAnnotation class]])
	{
		MKAnnotationView* annotationView = nil;
		if(nil == annotationView)
		{
			CSRouteView* routeView = [[[CSRouteView alloc] initWithFrame:CGRectMake(0, 0, self.mapView.frame.size.width, self.mapView.frame.size.height)] autorelease];
            
			routeView.annotation = routeAnnotation;
			routeView.mapView = self.mapView;
			theRouteView = routeView;
            
			annotationView = routeView;
            return annotationView;
		}
	}  else if ([annotation isKindOfClass:[MKUserLocation class]]) {
        // Do nothing if it is the user location
        return nil;
    } else if (annotation == landingLocAnnotation){
        // the estimated landing location
        annView.animatesDrop=YES;
		annView.pinColor = MKPinAnnotationColorPurple;
	} else if (annotation == lastLocAnnotation) {
        // Last transition annotation
        annView.animatesDrop=YES;
        annView.pinColor = MKPinAnnotationColorRed;
    }else {
        // Everything else
        annView.animatesDrop=NO;
		annView.pinColor = MKPinAnnotationColorGreen;
	}
		
    return annView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    DebugLog(@"Selected");
}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	// turn off the view of the route as the map is chaning regions. This prevents
	// the line from being displayed at an incorrect position on the map during the
	// transition. 
    if (self.theRouteView)
		theRouteView.hidden = YES;

}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	// re-enable and re-poosition the route display. 
	if (self.theRouteView){
		theRouteView.hidden = NO;
		[theRouteView regionChanged];
	}
	
}

#pragma mark -
#pragma mark Location manager

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
	
    if (locationManager != nil) {
		[locationManager setDesiredAccuracy:self.locationAccuracy];
		return locationManager;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDesiredAccuracy:self.locationAccuracy];
	[locationManager setDelegate:self];
	
	return locationManager;
}


/**
 Keep updating the location on the map
 */
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	if (!self.isPolling) {
        userLocAnnotation = mapView.userLocation;
        userLocation = userLocAnnotation.location.coordinate;
        MKCoordinateRegion region = mapView.region;
        region.center=userLocation;
        [mapView setRegion:region animated:TRUE];
        [mapView regionThatFits:region];
    }
}

/**
 Display an error if location manager fails
 */
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
	DebugLog(@"LocationManager failed!");
	UIAlertView *errorAlert = [[UIAlertView alloc]
							   initWithTitle: @"Error: Your Location"
							   message: @"locationManager failed.  We do not know where we are."
							   delegate:nil
							   cancelButtonTitle:@"OK"
							   otherButtonTitles:nil];
	[errorAlert show];
	[errorAlert release];
	
}

#pragma mark -
#pragma mark UIAlertViewDelegate functions
-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0) {
        replaceUUID = NO;
        self.scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
        scAppDel.currentUUID = conflictUUID;
        
    } else {
        replaceUUID = YES;
        conflictUUID = NO;
    }
}

#pragma mark -
#pragma mark UIPickerView

/**
 return the picker frame based on its size, positioned at the bottom of the page
 */
- (CGRect)pickerFrameWithSize:(CGSize)size
{
	CGRect screenRect = [[UIScreen mainScreen] applicationFrame];
	CGRect pickerRect = CGRectMake(	0.0,
								   screenRect.size.height - 84.0 - size.height,
								   size.width,
								   size.height);
	return pickerRect;
}

- (void)createPicker
{
	pickerViewArray = [[NSMutableArray alloc] init];
	
	NSMutableArray *accData6 = [[NSMutableArray alloc] init];
	[accData6 addObject:@"Best for Nav."];
	[accData6 addObject:[[NSNumber alloc] initWithDouble:kCLLocationAccuracyBestForNavigation]];
	[pickerViewArray addObject:accData6];
	[accData6 release];
	
	NSMutableArray *accData5 = [[NSMutableArray alloc] init];
	[accData5 addObject:@"Highest"];
	[accData5 addObject:[[NSNumber alloc] initWithDouble:kCLLocationAccuracyBest]];
	[pickerViewArray addObject:accData5];
	[accData5 release];
		
	NSMutableArray *accData4 = [[NSMutableArray alloc] init];
	[accData4 addObject:@"10 Meters"];
	[accData4 addObject:[[NSNumber alloc] initWithDouble:kCLLocationAccuracyNearestTenMeters]];
	[pickerViewArray addObject:accData4];
	[accData4 release];
	
	NSMutableArray *accData3 = [[NSMutableArray alloc] init];
	[accData3 addObject:@"Significant Only"];
	[accData3 addObject:[[NSNumber alloc] initWithDouble:kCLLocationAccuracyHundredMeters]];
	[pickerViewArray addObject:accData3];
	[accData3 release];
	
	/*NSMutableArray *accData2 = [[NSMutableArray alloc] init];
	[accData2 addObject:@"1 Km"];
	[accData2 addObject:[[NSNumber alloc] initWithDouble:kCLLocationAccuracyKilometer]];
	[pickerViewArray addObject:accData2];
	[accData2 release];
	
	NSMutableArray *accData1 = [[NSMutableArray alloc] init];
	[accData1 addObject:@"3 Km"];
	[accData1 addObject:[[NSNumber alloc] initWithDouble:kCLLocationAccuracyThreeKilometers]];
	[pickerViewArray addObject:accData1];
	[accData1 release];	*/
			
	// position the picker at the bottom
    // The device is an iPhone or iPod touch.
    accuracyPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 325, 250)];
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 160, 320, 40)];
    containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	
	CGRect pickerFrame = containerView.frame;
	pickerFrame.origin.y = 480;
	containerView.frame = pickerFrame;
	
	accuracyPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	accuracyPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	accuracyPickerView.delegate = self;
	accuracyPickerView.dataSource = self;
	
    // Initialize the toolbar items
	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(saveDesiredAccuracy)];
	UIBarButtonItem *cancelBarButtonItem2 = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(hidePicker)];
	UIBarButtonItem	*flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	[toolbar setBarStyle:UIBarStyleBlackTranslucent];
	
	NSArray *items = [[NSArray alloc] initWithObjects:cancelBarButtonItem2, flex, doneBarButtonItem , nil];
	[toolbar setItems:items];
    
	[containerView addSubview:accuracyPickerView];
	[containerView addSubview:toolbar];
    
	// add this picker to our view controller
	[self.view addSubview:containerView];
	
    pickerFrame.origin.y = 0;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:.2];
	containerView.frame = pickerFrame;
    [UIView commitAnimations];
    
    [items release];
    [doneBarButtonItem release];
    [cancelBarButtonItem2 release];
    [flex release];
}


- (void)hidePicker
{
	
	//picker frame
	CGRect pickerFrame = containerView.frame;
	
	//frame.size.height +=(pickerFrame.size.height -50);
	pickerFrame.origin.y = 480;
	
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:.2];
    //self.view.frame = frame;
	containerView.frame = pickerFrame;
    [UIView commitAnimations];
	
    [self.containerView removeFromSuperview];
	[self.accuracyPickerView removeFromSuperview];
	[self.toolbar removeFromSuperview];
}

- (IBAction) saveDesiredAccuracy {
    
	self.accuracyButton.title = [[pickerViewArray objectAtIndex:[accuracyPickerView selectedRowInComponent:0]] objectAtIndex:0];
	self.locationAccuracy = [[[pickerViewArray objectAtIndex:[accuracyPickerView selectedRowInComponent:0]] objectAtIndex:1] doubleValue];
	
	if (self.locationAccuracy == kCLLocationAccuracyBestForNavigation){
		self.accuracyButton.title = @"BEST For Nav.";
        self.desiredAccuracy = @"bestfornav";
        
        MKCoordinateRegion region = mapView.region;
        MKCoordinateSpan span;
		span.latitudeDelta=0.001;
		span.longitudeDelta=0.001;
        region.span=span;
        [mapView setRegion:region animated:TRUE];
        [mapView regionThatFits:region];
	} else {
        if (self.locationAccuracy == kCLLocationAccuracyBest){
            self.accuracyButton.title = @"Best Acc.";
            self.desiredAccuracy = @"best";
        } else if (self.locationAccuracy == kCLLocationAccuracyNearestTenMeters){
            self.accuracyButton.title = @"Nearest 10m";
            self.desiredAccuracy = @"nearest10";
        } else {
            self.accuracyButton.title = @"Significant";
            self.desiredAccuracy = @"significant";
            self.locationAccuracy = kCLLocationAccuracyNearestTenMeters;
        }
		
	}
	
	[self.locationManager setDesiredAccuracy:self.locationAccuracy];
	
	[self hidePicker];
	
}

/**
 Display the picker
 */
-(IBAction) chooseAccuracy {
	[self createPicker];
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	// don't show selection for the custom picker
}


#pragma mark -
#pragma mark UIPickerViewDataSource

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	NSString *returnStr = @"";
	
	// note: custom picker doesn't care about titles, it uses custom views

	if (component == 0)
	{
		returnStr = [[pickerViewArray objectAtIndex:row] objectAtIndex:0] ;
	}
	
	return returnStr;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	CGFloat componentWidth = 0.0;
	
	if (component == 0)
		componentWidth = 180.0;	
	
	return componentWidth;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [pickerViewArray count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// the user pressed the "Done" button, so dismiss the keyboard
    tripidUpdated = YES;
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    tripidUpdated = YES;
    self.launchButton.enabled = YES;
    if ([self.pollButton.title isEqualToString:@"Resume"]) {
        self.pollButton.title = @"Restart";
    }
    self.desiredAccuracy = @"Success";
	return YES;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.

	mapView = nil;
	[mapView release];	
	userLocAnnotation = nil;
	[userLocAnnotation release];
	foundLocations = nil;
	[foundLocations release];
    
    
    mapView = nil;
    _contentView = nil;
    accuracyButton = nil;
    pollButton = nil;
    refreshButton = nil;
    launchButton = nil;
    tripid = nil;
    pickerViewArray = nil;
    accuracyPickerView = nil;
    navBar = nil;
    containerView = nil;
    toolbar = nil;
    updateTimer = nil;
    scAppDel = nil;
    startLocation = nil;
    aLocation = nil;
    endLocation = nil;
    userLocAnnotation = nil;
    lastLocAnnotation = nil;
    foundLocations = nil;
    locationManager = nil;
    lastTimestamp = nil;
    desiredAccuracy = nil;
	
    [mapView release];	
	[userLocAnnotation release];
    [lastLocAnnotation release];
	[foundLocations release];
    [_contentView release];
    [accuracyButton release];
    [pollButton release];
    [refreshButton release];
    [launchButton release];
    [tripid release];
    [pickerViewArray release];
    [accuracyPickerView release];
    [navBar release];
    [containerView release];
    [toolbar release];
    [updateTimer release];
    [scAppDel release];
    [startLocation release];
    [aLocation release];
    [endLocation release];
    [locationManager release];
    [lastTimestamp release];
    [desiredAccuracy release];
}


- (void)dealloc {
    [super dealloc];
	
	[mapView release];	
	[userLocAnnotation release];
    [lastLocAnnotation release];
	[foundLocations release];
    [_contentView release];
    [accuracyButton release];
    [pollButton release];
    [refreshButton release];
    [launchButton release];
    [tripid release];
    [pickerViewArray release];
    [accuracyPickerView release];
    [navBar release];
    [containerView release];
    [toolbar release];
    [updateTimer release];
    [scAppDel release];
    [startLocation release];
    [aLocation release];
    [endLocation release];
    [locationManager release];
    [lastTimestamp release];
    [desiredAccuracy release];
}


@end
