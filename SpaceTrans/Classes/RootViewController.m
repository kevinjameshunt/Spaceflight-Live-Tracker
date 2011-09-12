//
//  RootViewController.m
//  SpaceTrans 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import "RootViewController.h"
#import "JSON.h"

#define kHEADING_UP 0
#define kABOVE_TOWERS 1
#define kHEADING_DOWN 2
#define kFIND_ME 10

#define kTimerVal 600 // seconds
#define kdistanceFilter 100 // metres
#define kdistanceFilterBest 5 // metres
#define kOldLocationCheckInterval 10 // seconds

@implementation RootViewController

@synthesize timeStamp, locationManager, locObj, statusLabel, logView, transButton, foundButton, urlField, url, tripid, timer;
@synthesize isTransmitting, state, internetReach, latestLoc;


- (void) updateOnSignificantChanges {
	[self.timer invalidate];
	[self setTimer:nil];
	if (state < kHEADING_DOWN) {
        DebugLog(@"Updating on Significant Location Changes only (accuracy set to nearest 3Km for 3G phones).");
        
        self.logView.text = [self.logView.text stringByAppendingString:@"\nUpdating on Significant Location Changes only (accuracy set to nearest 3Km for 3G phones)."];
		state = kABOVE_TOWERS;
		[self.locationManager stopUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        [self.locationManager startUpdatingLocation];
	}
}

-(void) setLocationAccuracy:(CLLocationAccuracy)accuracy {
	if (state == kABOVE_TOWERS) {
		[self.locationManager stopMonitoringSignificantLocationChanges];
	} 
    [self.locationManager stopUpdatingLocation];

    // If we've set "best" or "best for nav" (greatest battery drain), update distance filter
    if (accuracy == kCLLocationAccuracyBestForNavigation) {
        state = kFIND_ME;
        self.locationManager.distanceFilter = kdistanceFilterBest;
    }else {
        state = kHEADING_DOWN;
        if (accuracy == kCLLocationAccuracyBest) {
            self.locationManager.distanceFilter = kdistanceFilterBest;
        } else {
            self.locationManager.distanceFilter = kdistanceFilter;
        }
    }
    
	self.locationManager.desiredAccuracy = accuracy;
	[self.locationManager startUpdatingLocation];
}

-(void) sendData:(CLLocation *)newLocation {
    // if we have a URL to send it to, send the location object
    if (self.url && newLocation) {
        
        // Get values from location object
        CLLocationCoordinate2D coordinate = [newLocation coordinate];
        NSString *longitude = [[NSString alloc] initWithFormat:@"%lf", coordinate.longitude];
        NSString *latitude = [[NSString alloc] initWithFormat:@"%lf", coordinate.latitude];
        NSString *altitude = [[NSString alloc] initWithFormat:@"%lf", newLocation.altitude];
        NSString *accuracy = [[NSString alloc] initWithFormat:@"%lf", newLocation.horizontalAccuracy];
        NSString *altitudeAccuracy = [[NSString alloc] initWithFormat:@"%lf", newLocation.verticalAccuracy];
        NSString *heading = [[NSString alloc] initWithFormat:@"%lf", newLocation.course];
        NSString *speed = [[NSString alloc] initWithFormat:@"%lf", newLocation.speed];
        float batLevel = [[UIDevice currentDevice] batteryLevel];
        
        // Format timestamp
        NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
        [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timestamp = [[outputFormatter stringFromDate:newLocation.timestamp] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        // Construct POST data
        NSString *urlString = [[NSString alloc] initWithFormat:@"longitude=%@",longitude];
        urlString = [urlString stringByAppendingFormat:@"&latitude=%@",latitude];
        urlString = [urlString stringByAppendingFormat:@"&altitude=%@",altitude];
        urlString = [urlString stringByAppendingFormat:@"&accuracy=%@",accuracy];
        urlString = [urlString stringByAppendingFormat:@"&altitudeAccuracy=%@",altitudeAccuracy];
        urlString = [urlString stringByAppendingFormat:@"&heading=%@",heading];
        urlString = [urlString stringByAppendingFormat:@"&speed=%@",speed];
        urlString = [urlString stringByAppendingFormat:@"&tripid=%@",self.tripid.text];
        urlString = [urlString stringByAppendingFormat:@"&timestamp=%@",timestamp];
        urlString = [urlString stringByAppendingFormat:@"&appstate=%d",self.state];
        urlString = [urlString stringByAppendingFormat:@"&batlevel=%0.2f", batLevel * 100];
        if (foundButton.enabled == NO)
            urlString = [urlString stringByAppendingString:@"&found=1"];
        
        // Convert to data
        NSData *myRequestData = [ NSData dataWithBytes: [ urlString UTF8String ] length: [ urlString length ] ];
        
        DebugLog(@"%@",urlString);

        
        // Create request
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[url stringByAppendingString:@"/submitLoc.php"]]]; 
        [request setHTTPMethod: @"POST"];
        [request setHTTPBody: myRequestData];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        
        // Send request
        NSHTTPURLResponse* response = nil;  
        NSError* error = [[NSError alloc] init];  
        NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error ];
        
        // Display result in log
        NSString *result = [[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding];
        DebugLog(@"Send result: %@",result);
        
#ifdef DEBUG
        if (result && [result length] >0)
            self.logView.text = [self.logView.text stringByAppendingFormat:@"\nSend Result: %@.  Battery: %0.0f%%", result,[[UIDevice currentDevice] batteryLevel] * 100];
        else
            self.logView.text = [self.logView.text stringByAppendingFormat:@"\nSend Result: Nothing.  Battery: %0.0f%%", [[UIDevice currentDevice] batteryLevel] * 100];
#endif
        
        // If we are higher than 3,000m, we'll can manually tell it to only monitor significant changes
        if ([result isEqualToString:@"significant"]) {
            DebugLog(@"Notification received: Updating on significant changes only.");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nReceived notification to update on significant changes only."];
            [self updateOnSignificantChanges];
        } else if ([result isEqualToString:@"nearest10"] && state != kHEADING_UP) {
            DebugLog(@"Done heading up and accuracy is nearest10");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nDone heading up and accuracy is nearest10"];
            [self setLocationAccuracy:kCLLocationAccuracyNearestTenMeters];
        } else if ([result isEqualToString:@"best"] && state != kHEADING_UP) {
            DebugLog(@"Done heading up and accuracy is best");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nDone heading up and accuracy is best"];
            [self setLocationAccuracy:kCLLocationAccuracyBest];
        } else if ([result isEqualToString:@"bestfornav"] && state != kHEADING_UP) {
            DebugLog(@"Done heading up and accuracy is bestfornav");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nDone heading up and accuracy is bestfornav"];
            [self setLocationAccuracy:kCLLocationAccuracyBestForNavigation];
        } else if (newLocation.altitude > 3000 && state == kHEADING_UP){
            // Update on significant changes only to preserve battery power while out of tower range
            DebugLog(@"Heading up and now looking for significant changes only.");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nHeading up above towers and now looking for significant changes only."];
            [self updateOnSignificantChanges];
        } else if (newLocation.verticalAccuracy > -1 && newLocation.altitude < 3000 && state == kABOVE_TOWERS ) {
            // We WERE above the tower range but are now lower than 3,000m
            DebugLog(@"Heading down from above towers.  Accuracy set to nearest 10");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nHeading down from above towers.  Accuracy set to nearest 10m."];
            [self setLocationAccuracy:kCLLocationAccuracyNearestTenMeters];
        } else if (state == kHEADING_UP){
            // Else, restart the timer and wait for the time interval before we start only monitoring significant changes
            DebugLog(@"Still heading up.  Timer set.");  
            self.logView.text = [self.logView.text stringByAppendingString:@"\nStill heading up.  Timer reset."];
            [self setTimer:[NSTimer scheduledTimerWithTimeInterval:kTimerVal target:self selector:@selector(updateOnSignificantChanges) userInfo:nil repeats:NO]];
        }
        
        [longitude release];
        [latitude release];
        [altitude release];
        [accuracy release];
        [altitudeAccuracy release];
        [heading release];
        [speed release];
        [outputFormatter release];
        [result release];
        [request release];
    }
}

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
    [super viewDidLoad];

    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    
	self.navigationItem.title = @"Space Transmitter";
	
	// Create new object and set properties
	self.locationManager = [[[CLLocationManager alloc] init] autorelease];
	self.locationManager.delegate = self; // send loc updates to myself
	
	// Get location using the second best accuracy, but only receive updates when the device has moved more than 50 metres
	self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
	self.locationManager.distanceFilter = kdistanceFilter;
	
	// Set default values
	self.isTransmitting = NO;
	state = kHEADING_UP;
	urlField.enabled = YES;
	
    // Retrieve previously used values
	self.url = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverUrl"];
	if (self.url) {
		urlField.text = url;
	}
	NSInteger tripNo = [[NSUserDefaults standardUserDefaults] integerForKey:@"tripid"];
	if (tripNo > 0) {
		tripid.text = [NSString stringWithFormat:@"%d", (tripNo+1)];
	} else {
		tripid.text = 0;
	}
    
    // Start checking for reachability
    internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier];
    
    // We want to monitor and report the power level of the battery, register the observers
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelDidChange:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification
                                               object:nil];
}


// Starts or stops location monitoring services, as well as related failsafes
- (IBAction) startUpdatingLocation {
    
	// Get URL from text field if it is editable
	if ([urlField isEnabled]) {
		url = urlField.text;
	}
	
	// if transmitting when button is pressed, stop
	if (self.isTransmitting) {
        
        // Stop updating location
		if (state == kABOVE_TOWERS) {
			[self.locationManager stopMonitoringSignificantLocationChanges];
        }
        [self.locationManager stopUpdatingLocation];
		
        self.isTransmitting = NO;
        
        // Update UI
		[self.transButton setTitle:@"Resume" forState:UIControlStateNormal];
        self.statusLabel.text = @"Location tracking paused.";
	} else{
		// if not transmitting, start!
		[[NSUserDefaults standardUserDefaults] setObject:url forKey:@"serverUrl"];
		[[NSUserDefaults standardUserDefaults] setObject:tripid.text forKey:@"tripid"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
        // hide the keyboard
        [urlField resignFirstResponder];
        [tripid resignFirstResponder];
        
        // start updating location again
		if (state == kABOVE_TOWERS) {
			[self.locationManager startMonitoringSignificantLocationChanges];
		} 
        [self.locationManager startUpdatingLocation];
		
		self.isTransmitting = YES;
        
        // Update UI
		[self.transButton setTitle:@"Pause" forState:UIControlStateNormal];
        self.statusLabel.text = @"Location tracking started.";
		urlField.enabled = NO;
		tripid.enabled = NO;
	}
}


// The device has been found, update UI and prepare to notify server
- (IBAction) registerFound {
    self.transButton.enabled = NO;
    self.foundButton.enabled = NO;
    self.logView.text = [self.logView.text stringByAppendingString:@"\nI've been found!"];
}



#pragma mark -
#pragma mark locationManager

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    DebugLog(@"Location: %@", [newLocation description]);
	
    // Use location only if we are sure that it isn't a cached location obj
    NSTimeInterval age = [newLocation.timestamp timeIntervalSinceNow];
    if(abs(age) < kOldLocationCheckInterval){
        
        // If an update has been received, clear the timer
        if (timer) {
            [timer invalidate];
            [self setTimer:nil];
        } 
        
        // Send the data to teh server
        self.latestLoc = newLocation;
        [self sendData:newLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
    // Display an error, then set a new timer for significant updates only
	self.logView.text = [self.logView.text stringByAppendingFormat:@"\nLocation Manager failed with errors: %@\nSetting significant update timer.", [error localizedDescription]];
    [self.timer invalidate];
	[self setTimer:[NSTimer scheduledTimerWithTimeInterval:kTimerVal target:self selector:@selector(updateOnSignificantChanges) userInfo:nil repeats:NO]];
}

#pragma mark -
#pragma mark Reachability 

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	NetworkStatus netStatus = [curReach currentReachabilityStatus];
    switch (netStatus)
    {
        case NotReachable:
        {
            DebugLog(@"Access Not Available, stopping location service");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nAccess Not Available, stopping locaiton service"];
            if (state < kHEADING_DOWN) {
                state = kABOVE_TOWERS;
            }
            [self.locationManager stopMonitoringSignificantLocationChanges];
            [self.locationManager stopUpdatingLocation];
            break;
        }
            
        case ReachableViaWWAN:
        {
            DebugLog(@"Reachable WWAN, starting location service.");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nReachable WWAN, starting location service."];
            [self.locationManager startUpdatingLocation];
            break;
        }
        case ReachableViaWiFi:
        {
            DebugLog(@"Reachable WIFI, starting location service.");
            self.logView.text = [self.logView.text stringByAppendingString:@"\nReachable WIFI, starting location service."];
            [self.locationManager startUpdatingLocation];
            break;
        }
    }
}

#pragma mark -
#pragma mark batter level handler

// Failsafe to prevent iPhone 3G hardware bug, as well as force device to communicate with server
// Useful if the device has stopped moving but we need to tell it to update it's location accuracy setting
- (void)batteryLevelDidChange: (NSNotification* )note
{
    NSString *msg = [NSString stringWithFormat:
                     @"Battery charge level: %.0f%%", [[UIDevice currentDevice] batteryLevel] * 100];
    self.logView.text = [self.logView.text stringByAppendingFormat:@"\n%@",msg];
    DebugLog(@"%@", msg);
    
    if (self.isTransmitting) {
        [self sendData:[locationManager location]];
    }
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	// the user pressed the "Done" button, so dismiss the keyboard
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Clear the log in the UI
    self.logView.text = @"Memory warning, clearing log to preserve application.\n";
}

- (void)viewDidUnload {
    locationManager = nil;
    timeStamp = nil;
    locObj = nil;
    statusLabel = nil;
    logView = nil;
    transButton = nil;
    urlField = nil;
    url = nil;
    tripid = nil;
    timer = nil;
    internetReach = nil;
    
    [self.locationManager release];
    [locationManager release];
    [timeStamp release];
    [locObj release];
    [statusLabel release];
    [logView release];
    [transButton release];
    [urlField release];
    [url release];
    [tripid release];
    [timer release];
    [internetReach release];
}


- (void)dealloc {
    [self.locationManager release];
    [locationManager release];
    [timeStamp release];
    [locObj release];
    [statusLabel release];
    [logView release];
    [transButton release];
    [urlField release];
    [url release];
    [tripid release];
    [timer release];
    [internetReach release];
    [super dealloc];
}


@end

