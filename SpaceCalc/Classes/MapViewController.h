//
//  MapViewController.h
//  SpaceCalc 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MapKit/MKPinAnnotationView.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationData.h"
#import "CSRouteAnnotation.h"
#import "CSRouteView.h"

@class SpaceCalcAppDelegate;

@interface LocationAnnotation : NSObject<MKAnnotation> {
	CLLocationCoordinate2D  coordinate;
	CLLocation *            theLocation;
	NSString *              mTitle;
	NSString *              mSubTitle;
}

@property (nonatomic, retain) NSString *    mTitle;
@property (nonatomic, retain) NSString *    mSubTitle;
@property (nonatomic, retain) CLLocation *  theLocation;

@end


@interface MapViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate, UINavigationBarDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate> {

	MKMapView *             mapView;
	UIView *                _contentView;
	UIBarButtonItem *       accuracyButton;
	UIBarButtonItem *       pollButton;
    UIBarButtonItem *       refreshButton;
    UIBarButtonItem *       launchButton;
	UITextField *           tripid;
	NSMutableArray *        pickerViewArray;
	UIPickerView *          accuracyPickerView;
	UINavigationItem *      navBar;
    UIView *                containerView;
	UIToolbar *             toolbar;
    UIActivityIndicatorView *spinner;
	
	NSTimer *               updateTimer;
	SpaceCalcAppDelegate *  scAppDel;
    LocationData *          startLocation;
	LocationData *          aLocation;
    LocationData *          endLocation;
	MKUserLocation *        userLocAnnotation;
    LocationAnnotation *    landingLocAnnotation;
    LocationAnnotation *    lastLocAnnotation;
    CSRouteAnnotation *     routeAnnotation;
    CSRouteView *           theRouteView;
	NSMutableArray *        foundLocations;
	CLLocationCoordinate2D  userLocation;
	CLLocationManager *     locationManager;
	CLLocationAccuracy      locationAccuracy;
	
	NSString *              lastTimestamp;
    NSString *              launchTimestamp;
    NSString *              desiredAccuracy;
    NSString *              conflictUUID;
	bool                    isPolling;
    bool                    tripidUpdated;
    bool                    replaceUUID;
}

@property (nonatomic, retain) IBOutlet MKMapView *      mapView;
@property (nonatomic, retain) IBOutlet UIView *         contentView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *accuracyButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *pollButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *refreshButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *launchButton;
@property (nonatomic, retain) IBOutlet UITextField *    tripid;
@property (nonatomic, retain) NSMutableArray	*       pickerViewArray;
@property (nonatomic, retain) UIPickerView *            accuracyPickerView;
@property (nonatomic, retain) IBOutlet UINavigationItem *navBar;
@property (nonatomic, retain) UIView *                  containerView;
@property (nonatomic, retain) UIToolbar *               toolbar;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, retain) NSTimer *updateTimer;
@property (nonatomic, retain) SpaceCalcAppDelegate *    scAppDel;
@property (nonatomic, retain) LocationData *            startLocation;
@property (nonatomic, retain) LocationData *            aLocation;
@property (nonatomic, retain) LocationData *            endLocation;
@property (nonatomic, retain) MKUserLocation *          userLocAnnotation;
@property (nonatomic, retain) LocationAnnotation *      landingLocAnnotation;
@property (nonatomic, retain) LocationAnnotation *      lastLocAnnotation;
@property (nonatomic, retain) CSRouteAnnotation *       routeAnnotation;
@property (nonatomic, retain) CSRouteView *             theRouteView;
@property (nonatomic, retain) NSMutableArray *          foundLocations;
@property (nonatomic) CLLocationCoordinate2D            userLocation;
@property (nonatomic, retain) CLLocationManager *       locationManager;
@property (nonatomic) CLLocationAccuracy                locationAccuracy;

@property (nonatomic, retain) NSString *                lastTimestamp;
@property (nonatomic, retain) NSString *                launchTimestamp;
@property (nonatomic, retain) NSString *                desiredAccuracy;
@property (nonatomic, retain) NSString *                conflictUUID;

@property (nonatomic) bool                              isPolling;
@property (nonatomic) bool                              tripidUpdated;
@property (nonatomic) bool                              replaceUUID;

- (IBAction) startPolling;
- (IBAction) refreshBtnPressed;
- (IBAction) launchBtnPressed;

-(void) restoreDefaults;

- (void) updateMapView;
- (void) refreshMapView;
- (void) searchDb;

- (CGRect)pickerFrameWithSize:(CGSize)size;
- (void)createPicker;
- (void)hidePicker;
- (IBAction) saveDesiredAccuracy;
-(IBAction) chooseAccuracy;

@end
