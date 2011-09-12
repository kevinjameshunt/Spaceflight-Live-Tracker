//
//  BalloonDataViewController.m
//  SpaceCalc 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import "BalloonDataViewController.h"


#define kOldLocationCheckInterval 10 // seconds

@implementation BalloonDataViewController

@synthesize calcButton, clearButton, payloadMassField, balloonMassField, targetBurstAlfField, descRateField, urlField, ascentRateLbl, launchVolLbl, burstAltLbl, burstTimeLbl, fallingTimeLbl, totalTImeLbl, navBar, logView;
@synthesize currentPicker, balloonPickerView, currentField, pickerViewArray, toolbar, updateTimer, containerView, userLocation, locationManager;
@synthesize balloonMass, payloadMass, launchVol, targetBurstAlt, coefficientOfDrag, burstDiameter;


#pragma mark -
#pragma mark View Lifecycle

/**
 Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
*/
- (void)viewDidLoad {
    [super viewDidLoad];
	[self setNavBar:navBar];
    
    /*
	self.calcButton = [[[UIBarButtonItem alloc]
						 initWithTitle:@"Calc"
						 style:UIBarButtonItemStylePlain
						 target:self
						 action:@selector(calcData)] autorelease];
    
    self.clearButton = [[[UIBarButtonItem alloc]
                        initWithTitle:@"Clear"
                        style:UIBarButtonItemStylePlain
                        target:self
                        action:@selector(clearData)] autorelease];
	self.navBar.leftBarButtonItem = clearButton;
	self.navBar.leftBarButtonItem.enabled = YES;
    */
     
    // Retrieve values from previous session
    payloadMassField.text = [[[NSUserDefaults standardUserDefaults] objectForKey:@"payloadMass"] stringValue];
    targetBurstAlfField.text = [[[NSUserDefaults standardUserDefaults] objectForKey:@"targetBurstAlt"] stringValue];
    balloonMassField.text = [[[NSUserDefaults standardUserDefaults] objectForKey:@"balloonMass"] stringValue];
    descRateField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"descRate"];
    urlField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"serverUrl"];
    
    // Retrieve balloon data from previous session
    coefficientOfDrag = [[[NSUserDefaults standardUserDefaults] objectForKey:@"coefficientOfDrag"] doubleValue];
    burstDiameter = [[[NSUserDefaults standardUserDefaults] objectForKey:@"burstDiameter"] doubleValue];
    balloonMass = [[[NSUserDefaults standardUserDefaults] objectForKey:@"balloonMass"] doubleValue];
    
    // Start updating location
    [[self locationManager] startUpdatingLocation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    SpaceCalcAppDelegate *scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // If we already have a UUID, resume checking for it's progress
	if (scAppDel.predComplete == NO && scAppDel.currentUUID)
      [self setUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkPred) userInfo:nil repeats:YES]];  
}

- (void) viewWillDisappear:(BOOL)animated {
    
    // If we're checking the progress of a prediction, stop
    if (updateTimer) {
        [updateTimer invalidate];
        [self setUpdateTimer:nil];
    } 
}


#pragma mark -
#pragma mark Calculation and Prediction methods

/**
 Calculates values required to create prediction on server and updates UI with information for user
*/
-(IBAction) calcData {
	// Remove previous keyboards, pickers, and buttons
    [currentField resignFirstResponder];
    if (currentPicker != nil) {
        [self hidePicker:currentPicker];
    }
    
    // Stop updating location, as we're probably about to leave the view anyway
    [[self locationManager] stopUpdatingLocation];
    
    // Reset timer for checking on the prediction
    SpaceCalcAppDelegate *scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
    scAppDel.predComplete = NO;
    if (updateTimer) {
        [updateTimer invalidate];
        [self setUpdateTimer:nil];
    }
	
    // Get values needed for calculations
	payloadMass = [payloadMassField.text doubleValue];		// g
	targetBurstAlt = [targetBurstAlfField.text doubleValue]; // m

	launchVol = 0;										// m^3
	
    // Check for invalid inputs
    if (targetBurstAlt < 10000 || targetBurstAlt > 40000) {     // m
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle: @"Error In Parameters"
                                   message: @"Invalid Target Burst Altitude.  Must be greater than 10km and less than 40km"
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    } else if (payloadMass == 0 || payloadMass < 20 || payloadMass > 5000) {   // g
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle: @"Error In Parameters"
                                   message: @"Invalid Payload Mass.  Must be greater than 20g and less than 5kg"
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        [errorAlert show];
        [errorAlert release];
    } else{
        // Calculate our ascent rate
        
        // Set constants
        double densityOfHelium = 0.1786;			// kg / m^3
        double densityOfAir = 1.205;				// kg / m^3
        double airDensityModel = 7238.30;
        double gravitationalAcceleration = 9.80665;// m / s^2
        

        //Calculate data:
        double burstVolume = 4.00/3.00*M_PI*pow(burstDiameter/2.00, 3.00);			// m^3
        launchVol = burstVolume * pow(M_E,(-1.00*targetBurstAlt/airDensityModel)); // m^3
        
        double launchRadius = pow((3.00*launchVol)/(4.00*M_PI), 1.00/3.00);		// m
        double launchArea = M_PI * pow(launchRadius, 2.00);							// m^2
        double grossLift = launchVol * (densityOfAir - densityOfHelium);				// kg
        //double neckLift = (grossLift - balloonMass)* 1000.00;							// g
        double freeLift = ((grossLift - (balloonMass + payloadMass)/1000) * gravitationalAcceleration);	//g or kg?
        
        // Products
        double ascentRate = sqrtf(freeLift / (.5*coefficientOfDrag*launchArea*densityOfAir));	// m / s
        double burstAltitude = -1.00 * airDensityModel *log(launchVol/burstVolume);					// m
        double timeToBurst = (burstAltitude / ascentRate) / 60.00;									// min
        int hoursToBurst = (int)(timeToBurst/60);                                                   // hours
        int rminToBurst = (int)timeToBurst % 60;                                                 // min
        
        // Make sure we have a valid result
        if (isnan(timeToBurst)) {
            UIAlertView *errorAlert = [[UIAlertView alloc]
                                       initWithTitle: @"Error In Parameters"
                                       message: @"Invalid Payload Mass.  Must be greater than 20g and less than 5kg"
                                       delegate:nil
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [errorAlert show];
            [errorAlert release];
        } else {
            // If it looks good, update UI
            
            // Set labels
            ascentRateLbl.text = [NSString stringWithFormat:@"%.2f", ascentRate];
            launchVolLbl.text = [NSString stringWithFormat:@"%.2f", launchVol];
            burstAltLbl.text = [NSString stringWithFormat:@"%.0f", burstAltitude];
            burstTimeLbl.text = [NSString stringWithFormat:@"%d h, %d min", hoursToBurst, rminToBurst];
            
            // Store values for reuse
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:payloadMass] forKey:@"payloadMass"];
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:balloonMass] forKey:@"balloonMass"];
            [[NSUserDefaults standardUserDefaults] setValue:descRateField.text forKey:@"descRate"];
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:coefficientOfDrag] forKey:@"coefficientOfDrag"];
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:burstDiameter] forKey:@"burstDiameter"];
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithDouble:targetBurstAlt] forKey:@"targetBurstAlt"];
            [[NSUserDefaults standardUserDefaults] setObject:urlField.text forKey:@"serverUrl"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // Send scenario to server to start prediction
            [self sendScenario];
        }
    }
}

/**
 Clear UI and stored values
 */
-(IBAction) clearData {
	// Remove previous keyboards, pickers, and buttons
    [currentField resignFirstResponder];
    if (currentPicker != nil) {
        [self hidePicker:currentPicker];
    }
    
    // Reset UI
    payloadMassField.text = @"";
    targetBurstAlfField.text = @"";
    balloonMassField.text = @"";
    descRateField.text = @"";
    
    ascentRateLbl.text = @"0";
    launchVolLbl.text = @"0";
    burstAltLbl.text = @"0";
    burstTimeLbl.text = @"0";
    fallingTimeLbl.text = @"0";
    totalTImeLbl.text = @"0";
    
    
    // Clear values
    balloonMass = 0;
    payloadMass = 0;
    launchVol = 0;
    targetBurstAlt = 0;
    coefficientOfDrag = 0;
    burstDiameter = 0;
}

/**
 Send the scenario to CUSF Landing Predictor on server
 Handles UUID returned from server
 Sets timer to check prediction progress
 */
- (void) sendScenario {
    self.logView.text = [self.logView.text stringByAppendingFormat:@"Sending scenario to server...\n"];
    
    // Calculate future time
    NSDate *currentDateTime = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:currentDateTime]; // Get necessary date components;
    NSInteger hour = [components hour] + 1;
    NSInteger minute = [components minute];
    NSInteger month = [components month];
    NSInteger day = [components day];
    NSInteger year = [components year];
    
    //Generate search url
	NSString *siteName = [[NSString alloc] initWithFormat:@"%@/predictor/ajax.php?action=submitForm", urlField.text];
	NSString *urlString = [[NSString alloc] initWithString:@"submit=runprediction"];
	urlString = [urlString stringByAppendingFormat:@"&hour=%d",hour];
    urlString = [urlString stringByAppendingFormat:@"&min=%d", minute];
    urlString = [urlString stringByAppendingFormat:@"&sec=0"];
    urlString = [urlString stringByAppendingFormat:@"&month=%d",month];
    urlString = [urlString stringByAppendingFormat:@"&day=%d",day];
    urlString = [urlString stringByAppendingFormat:@"&year=%d",year];
    urlString = [urlString stringByAppendingFormat:@"&lat=%lf",userLocation.latitude];
    urlString = [urlString stringByAppendingFormat:@"&lon=%lf",userLocation.longitude];
    urlString = [urlString stringByAppendingFormat:@"&ascent=%@",ascentRateLbl.text];
    urlString = [urlString stringByAppendingFormat:@"&initial_alt=0"];
    urlString = [urlString stringByAppendingFormat:@"&drag=%@",descRateField.text];
    urlString = [urlString stringByAppendingFormat:@"&burst=%@",burstAltLbl.text];
    urlString = [urlString stringByAppendingFormat:@"&delta_lat=3"];
    urlString = [urlString stringByAppendingFormat:@"&delta_lon=3"];
    urlString = [urlString stringByAppendingFormat:@"&software=gfs"];
    urlString = [urlString stringByAppendingFormat:@"&launchsite=Other"];
    
	DebugLog(@"%@",urlString);
	
    // Create POST request
	NSData *myRequestData = [ NSData dataWithBytes: [ urlString UTF8String ] length: [ urlString length ] ];
	NSMutableURLRequest *request = [ [ NSMutableURLRequest alloc ] initWithURL: [ NSURL URLWithString:siteName ] ]; 
	[ request setHTTPMethod: @"POST" ];
	[ request setHTTPBody: myRequestData ];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	
    // Send request
	NSHTTPURLResponse* response = nil;  
	NSError* error = [[NSError alloc] init];  
	NSData *returnData = [ NSURLConnection sendSynchronousRequest: request returningResponse: &response error: &error ];
	
	// Display result in log
	NSString *result = [[NSString alloc] initWithData:returnData encoding:NSASCIIStringEncoding];
	DebugLog(@"%@",result);
    
    // Convert result from JSON string to NSDictionary
    SBJSON *jsonWriter = [[SBJSON new] autorelease];
    NSDictionary *dataDict = [jsonWriter objectWithString:result];
    NSString *valid = [dataDict objectForKey:@"valid"];
    NSString *uuid = [dataDict objectForKey:@"uuid"];
    NSString *predError = [dataDict objectForKey:@"error"];
    
    // If the scenario was valid, set timer to check status of prediction
    if ([valid isEqualToString:@"true"]){
        SpaceCalcAppDelegate *scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([uuid isEqualToString:scAppDel.currentUUID]) {
            self.logView.text = [self.logView.text stringByAppendingFormat:@"Trying again with same uid: %@.\nChecking for progress.json...\n",uuid];
            DebugLog(@"Same uuid: %@ returned.", uuid);
        } else {
            scAppDel.currentUUID = uuid;
            self.logView.text = [self.logView.text stringByAppendingFormat:@"New uuid: %@.\nChecking for progress.json...\n",uuid];
            DebugLog(@"Valid: %@. Uuid: %@",valid, uuid);
        }
        [self setUpdateTimer:[NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(checkPred) userInfo:nil repeats:YES]];
    } else {
        self.logView.text = [self.logView.text stringByAppendingFormat:@"Error with Prediction %@.  Try again.\n",predError];
        DebugLog(@"Error with Prediction %@.",predError);
    }
    
    [request release];
    [result release];
}

/**
 Check status of prediction on server
 */
- (void) checkPred {
	 SpaceCalcAppDelegate *scAppDel = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
	
    //Generate search url
	NSString *siteName = [[NSString alloc] initWithFormat:@"%@/checkPred.php", urlField.text];
	NSString *urlString = [[NSString alloc] initWithFormat:@"uuid=%@",scAppDel.currentUUID];
    
	DebugLog(@"%@",urlString);
	
    // Create POST Request
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
	
	if(success) {
		DebugLog(@"No Parsing Errors");
        
        // Display the message
        self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n",scAppDel.lastPredMessage];
        
        // if the prediction is done, stop the timers
        if ([scAppDel.lastPredMessage isEqualToString:@"Prediction finished."]) {
            if (updateTimer) {
                [updateTimer invalidate];
                [self setUpdateTimer:nil];
            }
        } else if ([scAppDel.lastPredMessage isEqualToString:@"Cannot find progress.json"]) {
            // Clear timers and try to create a new prediction
            
            self.logView.text = [self.logView.text stringByAppendingFormat:@"Creating new prediction.\n"];
            if (updateTimer) {
                [updateTimer invalidate];
                [self setUpdateTimer:nil];
            }
            [self sendScenario];
        }
	}
	else {
		DebugLog(@"Error Error Error in Parsing!!!");
        self.logView.text = [self.logView.text stringByAppendingString:@"Error in Parsing\n"];
    }
    
    [request release];
    [result release];
    [xmlParser release];
    [parser release];
}


#pragma mark -
#pragma mark Location manager

/**
 Return a location manager -- create one if necessary.
 */
- (CLLocationManager *)locationManager {
	
    if (locationManager != nil) {
		return locationManager;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	[locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
	[locationManager setDelegate:self];
	
	return locationManager;
}


/**
 Keep updating the location on the map
 */
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
	
    // Use location only if we are sure that it isn't a cached location obj
    NSTimeInterval age = [newLocation.timestamp timeIntervalSinceNow];
    if(abs(age) < kOldLocationCheckInterval)
    {
        userLocation = [newLocation coordinate];
        //DebugLog(@"Location: %@", [newLocation description]);
        //self.logView.text = [self.logView.text stringByAppendingFormat:@"%@\n",[newLocation description]];
        self.logView.text = [self.logView.text stringByAppendingString:@"Location updated.\n"];
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

/**
 Create the balloon size picker
 */
- (void)createPicker
{

	
	pickerViewArray = [[NSMutableArray alloc] init];
	
	NSMutableArray *kaymontData1 = [[NSMutableArray alloc] init];
	[kaymontData1 addObject:[[NSNumber alloc] initWithFloat:200]];
	[kaymontData1 addObject:[[NSNumber alloc] initWithFloat:3.00]];
	[kaymontData1 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData1];
	[kaymontData1 release];
	
	NSMutableArray *kaymontData2 = [[NSMutableArray alloc] init];
	[kaymontData2 addObject:[[NSNumber alloc] initWithFloat:300]];
	[kaymontData2 addObject:[[NSNumber alloc] initWithFloat:3.78]];
	[kaymontData2 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData2];
	[kaymontData2 release];

	
	NSMutableArray *kaymontData3 = [[NSMutableArray alloc] init];
	[kaymontData3 addObject:[[NSNumber alloc] initWithFloat:350]];
	[kaymontData3 addObject:[[NSNumber alloc] initWithFloat:4.12]];
	[kaymontData3 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData3];
	[kaymontData3 release];

	
	NSMutableArray *kaymontData4 = [[NSMutableArray alloc] init];
	[kaymontData4 addObject:[[NSNumber alloc] initWithFloat:450]];
	[kaymontData4 addObject:[[NSNumber alloc] initWithFloat:4.72]];
	[kaymontData4 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData4];
	[kaymontData4 release];
	
	NSMutableArray *kaymontData5 = [[NSMutableArray alloc] init];
	[kaymontData5 addObject:[[NSNumber alloc] initWithFloat:500]];
	[kaymontData5 addObject:[[NSNumber alloc] initWithFloat:4.99]];
	[kaymontData5 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData5];
	[kaymontData5 release];

	
	NSMutableArray *kaymontData6 = [[NSMutableArray alloc] init];
	[kaymontData6 addObject:[[NSNumber alloc] initWithFloat:600]];
	[kaymontData6 addObject:[[NSNumber alloc] initWithFloat:6.02]];
	[kaymontData6 addObject:[[NSNumber alloc] initWithFloat:0.3]];
	[pickerViewArray addObject:kaymontData6];
	[kaymontData6 release];

	
	NSMutableArray *kaymontData7 = [[NSMutableArray alloc] init];
	[kaymontData7 addObject:[[NSNumber alloc] initWithFloat:700]];
	[kaymontData7 addObject:[[NSNumber alloc] initWithFloat:6.53]];
	[kaymontData7 addObject:[[NSNumber alloc] initWithFloat:0.3]];
	[pickerViewArray addObject:kaymontData7];
	[kaymontData7 release];

	
	NSMutableArray *kaymontData8 = [[NSMutableArray alloc] init];
	[kaymontData8 addObject:[[NSNumber alloc] initWithFloat:800]];
	[kaymontData8 addObject:[[NSNumber alloc] initWithFloat:7.00]];
	[kaymontData8 addObject:[[NSNumber alloc] initWithFloat:0.3]];
	[pickerViewArray addObject:kaymontData8];
	[kaymontData8 release];

	
	NSMutableArray *kaymontData9 = [[NSMutableArray alloc] init];
	[kaymontData9 addObject:[[NSNumber alloc] initWithFloat:1000]];
	[kaymontData9 addObject:[[NSNumber alloc] initWithFloat:7.86]];
	[kaymontData9 addObject:[[NSNumber alloc] initWithFloat:0.3]];
	[pickerViewArray addObject:kaymontData9];
	[kaymontData9 release];

	
	NSMutableArray *kaymontData10 = [[NSMutableArray alloc] init];
	[kaymontData10 addObject:[[NSNumber alloc] initWithFloat:1200]];
	[kaymontData10 addObject:[[NSNumber alloc] initWithFloat:8.63]];
	[kaymontData10 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData10];
	[kaymontData10 release];
	
	NSMutableArray *kaymontData11 = [[NSMutableArray alloc] init];
	[kaymontData11 addObject:[[NSNumber alloc] initWithFloat:1500]];
	[kaymontData11 addObject:[[NSNumber alloc] initWithFloat:9.44]];
	[kaymontData11 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData11];
	[kaymontData11 release];

	NSMutableArray *kaymontData12 = [[NSMutableArray alloc] init];
	[kaymontData12 addObject:[[NSNumber alloc] initWithFloat:2000]];
	[kaymontData12 addObject:[[NSNumber alloc] initWithFloat:10.54]];
	[kaymontData12 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData12];
	[kaymontData12 release];

	NSMutableArray *kaymontData13 = [[NSMutableArray alloc] init];
	[kaymontData13 addObject:[[NSNumber alloc] initWithFloat:3000]];
	[kaymontData13 addObject:[[NSNumber alloc] initWithFloat:13.00]];
	[kaymontData13 addObject:[[NSNumber alloc] initWithFloat:0.25]];
	[pickerViewArray addObject:kaymontData13];
	[kaymontData13 release];
    
    
    balloonPickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 200, 325, 250)];
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 160, 320, 40)];
    containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	
	CGRect pickerFrame = containerView.frame;
	pickerFrame.origin.y = 480;
	containerView.frame = pickerFrame;
	
	balloonPickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	balloonPickerView.showsSelectionIndicator = YES;	// note this is default to NO
	
	// this view controller is the data source and delegate
	balloonPickerView.delegate = self;
	balloonPickerView.dataSource = self;
	
    // Initialize the toolbar items
	UIBarButtonItem *doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(saveBalloonMass)];
	UIBarButtonItem *cancelBarButtonItem2 = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(hidePicker)];
	UIBarButtonItem	*flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	
	[toolbar setBarStyle:UIBarStyleBlackTranslucent];
	
	NSArray *items = [[NSArray alloc] initWithObjects:cancelBarButtonItem2, flex, doneBarButtonItem , nil];
	[toolbar setItems:items];
    
	[containerView addSubview:balloonPickerView];
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

/**
 Display the balloon size picker
 */
- (void)showPicker:(UIView *)picker
{
	currentPicker = picker;	// remember the current picker so we can remove it later when another one is chosen
	currentPicker.hidden = NO;
	
	
	[self createPicker];
}

/**
 Hide the picker
 */
- (void)hidePicker:(UIView *)picker
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
	[self.balloonPickerView removeFromSuperview];
	[self.toolbar removeFromSuperview];
	
	currentField = nil;
	currentPicker = nil;
}

/**
 Save the ballon size for calculations
 */
- (IBAction) saveBalloonMass {
	self.balloonMassField.text = [[[pickerViewArray objectAtIndex:[balloonPickerView selectedRowInComponent:0]] objectAtIndex:0] stringValue];
	
	balloonMass = [[[pickerViewArray objectAtIndex:[balloonPickerView selectedRowInComponent:0]] objectAtIndex:0] doubleValue];
	burstDiameter = [[[pickerViewArray objectAtIndex:[balloonPickerView selectedRowInComponent:0]] objectAtIndex:1] doubleValue];
	coefficientOfDrag = [[[pickerViewArray objectAtIndex:[balloonPickerView selectedRowInComponent:0]] objectAtIndex:2] doubleValue];
	
	[self hidePicker:balloonPickerView];
	
}
	 
#pragma mark -
#pragma mark UIPickerViewDelegate
	 
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == balloonPickerView)	// don't show selection for the custom picker
    {
        
    }
    
}
	 
	 
#pragma mark -
#pragma mark UIPickerViewDataSource
	 
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *returnStr = @"";
    
    // note: custom picker doesn't care about titles, it uses custom views
    if (pickerView == balloonPickerView)
    {
        if (component == 0)
        {
            returnStr = [[[pickerViewArray objectAtIndex:row] objectAtIndex:0] stringValue] ;
        }
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
	[textField resignFirstResponder];
	//self.navBar.rightBarButtonItem  = nil;
    if (currentField == urlField) {
        [[NSUserDefaults standardUserDefaults] setObject:urlField.text forKey:@"serverUrl"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
	currentField = nil;
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	if (currentField != textField) {
		
		// Remove previous keyboards, pickers, and buttons
		[currentField resignFirstResponder];
		if (currentPicker != nil) {
			[self hidePicker:currentPicker];
		}
		//self.navBar.rightBarButtonItem  = nil;
		
		// Assign new text field
		currentField = textField;
		
		
		if (currentField == balloonMassField) {
			[self showPicker:balloonPickerView];
			
			
			return NO;
		} else {
			return YES;
		}
	} else if ((textField == balloonMassField)) {
		return NO;
	} else {
		return YES;
	}
}


#pragma mark -
#pragma mark Memory Management


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	
    calcButton = nil;
    payloadMassField = nil;
    balloonMassField = nil;
    launchVolLbl = nil;
    targetBurstAlfField = nil;
    ascentRateLbl = nil;
    burstAltLbl = nil;
    burstTimeLbl = nil;
    fallingTimeLbl = nil;
    totalTImeLbl = nil;
    navBar = nil;
    logView = nil;
    currentPicker = nil;
    balloonPickerView = nil;
    currentField = nil;
    pickerViewArray = nil;
    locationManager = nil;
    updateTimer = nil;
	
	[calcButton release];
	[payloadMassField release];
	[balloonMassField release];
	[launchVolLbl release];
	[targetBurstAlfField release];
	[ascentRateLbl release];
	[burstAltLbl release];
	[burstTimeLbl release];
	[fallingTimeLbl release];
	[totalTImeLbl release];
	[navBar release];
    [logView release];
    [updateTimer release];
    
    [locationManager release];
    
    [currentPicker release];
    [balloonPickerView release];
    [currentField release];
    [pickerViewArray release];
	
	/*[balloonMass release];
	[payloadMass release];
	[launchVol release];
	[targetBurstAlt release];
	
	[coefficientOfDrag release];
	[burstDiameter release];
	 */
}


- (void)dealloc {
    [super dealloc];
	
	
	[calcButton release];
	[payloadMassField release];
	[balloonMassField release];
	[launchVolLbl release];
	[targetBurstAlfField release];
	[ascentRateLbl release];
	[burstAltLbl release];
	[burstTimeLbl release];
	[fallingTimeLbl release];
	[totalTImeLbl release];
	[navBar release];
    [logView release];
    
    [locationManager release];
    
    [currentPicker release];
    [balloonPickerView release];
    [currentField release];
    [pickerViewArray release];
	

	/*[balloonMass release];
	[payloadMass release];
	[launchVol release];
	[targetBurstAlt release];
	[coefficientOfDrag release];
	[burstDiameter release];
	 */
}

@end
