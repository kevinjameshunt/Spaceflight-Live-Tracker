//
//  LocationData.h
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
#import <CoreLocation/CoreLocation.h>


@interface LocationData : CLLocation {
	double		longitude;
	double		latitude;
	double		altitude;
	double		horizontalAccuracy;
	double		verticalAccuracy;
	double		course;
	double		speed;
    double		appstate;
    double		batlevel;
	NSInteger	tripid;
	NSString *	theTimestamp;
	CLLocation *theLocation;
}

@property (nonatomic, readwrite) double		longitude;
@property (nonatomic, readwrite) double		latitude;
@property (nonatomic, readwrite) double		altitude;
@property (nonatomic, readwrite) double		horizontalAccuracy;
@property (nonatomic, readwrite) double		verticalAccuracy;
@property (nonatomic, readwrite) double		course;
@property (nonatomic, readwrite) double		speed;
@property (nonatomic, readwrite) double		appstate;
@property (nonatomic, readwrite) double		batlevel;
@property (nonatomic, readwrite) NSInteger	tripid;
@property (nonatomic, retain) NSString *	theTimestamp;
@property (nonatomic, retain) CLLocation *	theLocation;

- (CLLocation *) getLocation;
- (CLLocationCoordinate2D) getCoordinate;
@end
