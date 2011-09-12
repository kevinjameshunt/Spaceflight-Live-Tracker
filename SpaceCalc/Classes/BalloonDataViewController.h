//
//  BalloonDataViewController.h
//  SpaceCalc 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import <Foundation/Foundation.h>
#import <math.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LocXMLParser.h"
#import "JSON.h"
#import "SpaceCalcAppDelegate.h"

@class SpaceCalcAppDelegate;

@interface BalloonDataViewController : UIViewController <UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UINavigationBarDelegate, CLLocationManagerDelegate> {

	UIBarButtonItem	*   calcButton;
    UIBarButtonItem	*   clearButton;
	UITextField *       payloadMassField;
	UITextField *       balloonMassField;
	UITextField *       targetBurstAlfField;
    UITextField *       descRateField;
    UITextField *       urlField;
	UILabel		*       ascentRateLbl;
    UILabel     *       launchVolLbl;
	UILabel		*       burstAltLbl;
	UILabel		*       burstTimeLbl;
	UILabel		*       fallingTimeLbl;
	UILabel		*       totalTImeLbl;
	UINavigationItem *  navBar;
    UITextView *        logView;
	
	UIView			*   currentPicker;
	UIPickerView	*   balloonPickerView;
	UITextField		*   currentField;
	NSMutableArray	*   pickerViewArray;
    UIView          *   containerView;
	UIToolbar       *   toolbar;
    NSTimer         *   updateTimer;
    
    CLLocationCoordinate2D  userLocation;
	CLLocationManager *     locationManager;
	
	double balloonMass;
	double payloadMass;
	double launchVol;
	double targetBurstAlt;
	double coefficientOfDrag;
	double burstDiameter;

}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *    calcButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem	*   clearButton;
@property (nonatomic, retain) IBOutlet UITextField *        payloadMassField;
@property (nonatomic, retain) IBOutlet UITextField *        balloonMassField;
@property (nonatomic, retain) IBOutlet UITextField *        targetBurstAlfField;
@property (nonatomic, retain) IBOutlet UITextField *        descRateField;
@property (nonatomic, retain) IBOutlet UITextField *        urlField;
@property (nonatomic, retain) IBOutlet UILabel     *        ascentRateLbl;
@property (nonatomic, retain) IBOutlet UILabel     *        launchVolLbl;
@property (nonatomic, retain) IBOutlet UILabel *            burstAltLbl;
@property (nonatomic, retain) IBOutlet UILabel *            burstTimeLbl;
@property (nonatomic, retain) IBOutlet UILabel *            fallingTimeLbl;
@property (nonatomic, retain) IBOutlet UILabel *            totalTImeLbl;
@property (nonatomic, retain) IBOutlet UINavigationItem *   navBar;
@property (nonatomic, retain) IBOutlet UITextView *         logView;

@property (nonatomic, retain) UIView *                      currentPicker;
@property (nonatomic, retain) UIPickerView *                balloonPickerView;
@property (nonatomic, retain) UITextField *                 currentField;
@property (nonatomic, retain) NSMutableArray	*           pickerViewArray;
@property (nonatomic, retain) UIView          *             containerView;
@property (nonatomic, retain) UIToolbar       *             toolbar;
@property (nonatomic, retain) NSTimer *                     updateTimer;

@property (nonatomic) CLLocationCoordinate2D                userLocation;
@property (nonatomic, retain) CLLocationManager *           locationManager;

@property (nonatomic) double balloonMass;
@property (nonatomic) double payloadMass;
@property (nonatomic) double launchVol;
@property (nonatomic) double targetBurstAlt;
@property (nonatomic) double coefficientOfDrag;
@property (nonatomic) double burstDiameter;


- (IBAction) calcData;
- (IBAction) clearData;

- (CGRect)pickerFrameWithSize:(CGSize)size;
- (void)createPicker;
- (void)hidePicker:(UIView *)picker;
- (void)showPicker:(UIView *)picker;
- (void) sendScenario;
- (void) checkPred;

@end
