//
//  XMLParser.h
//  
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
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationData.h"

@class SpaceCalcAppDelegate;

@interface LocXMLParser : NSObject <NSXMLParserDelegate>{
	
	NSMutableString *currentElementValue;
	
	SpaceCalcAppDelegate *appDelegate;
	LocationData *locData;
}

@property (nonatomic, retain) CLLocation *locData;

- (LocXMLParser *) initXMLParser;

@end