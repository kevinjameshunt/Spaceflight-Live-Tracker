//
//  RootViewController.h
//  SpaceTrans 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "Reachability.h"

@class Reachability;

@interface RootViewController : UIViewController <CLLocationManagerDelegate>{
	NSDate *			timeStamp;
	CLLocationManager *	locationManager;
	NSString *			locObj;
	UILabel *			statusLabel;
    UITextView *        logView;
	UIButton *			transButton;
    UIButton *          foundButton;
	UITextField *		urlField;
	NSString *			url;
	UITextField *		tripid;
	NSTimer *			timer;
	NSInteger			state;
	BOOL				isTransmitting;
    Reachability*       internetReach;
    CLLocation*         latestLoc;
}

@property (nonatomic, retain) CLLocationManager *	locationManager;
@property (nonatomic, retain) NSDate *				timeStamp;
@property (nonatomic, retain) NSString *			locObj;
@property (nonatomic, retain) IBOutlet UILabel *	statusLabel;
@property (nonatomic, retain) IBOutlet UITextView *	logView;
@property (nonatomic, retain) IBOutlet UIButton *	transButton;
@property (nonatomic, retain) IBOutlet UIButton *	foundButton;
@property (nonatomic, retain) IBOutlet UITextField *urlField;
@property (nonatomic, retain) NSString *			url;
@property (nonatomic, retain) IBOutlet UITextField *tripid;
@property (nonatomic, retain) NSTimer *				timer;
@property (nonatomic, readwrite) NSInteger			state;
@property (nonatomic) BOOL							isTransmitting;
@property (nonatomic, retain) Reachability*         internetReach;
@property (nonatomic, retain) CLLocation*           latestLoc;

- (void) sendData:(CLLocation *)newLocation;
- (IBAction) startUpdatingLocation;
- (void) updateOnSignificantChanges;
- (void) setLocationAccuracy:(CLLocationAccuracy)accuracy;
- (void) reachabilityChanged: (NSNotification* )note;
- (void)batteryLevelDidChange: (NSNotification* )note;

@end
