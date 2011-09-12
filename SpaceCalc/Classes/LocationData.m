//
//  LocationData.m
//  SpaceCalc 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import "LocationData.h"


@implementation LocationData

@synthesize longitude, latitude, tripid, altitude, horizontalAccuracy, verticalAccuracy, course, speed, appstate, batlevel, theTimestamp, theLocation;


- (id)initWithLatitude:(CLLocationDegrees)alatitude longitude:(CLLocationDegrees)alongitude {
	latitude = alatitude;
	longitude = alongitude;
	self = [super initWithLatitude:latitude longitude:longitude];
	if (self != nil) {
		self.tripid = -1;
	}
	return self;
}

// Return coordinate type
- (CLLocationCoordinate2D) getCoordinate {
	CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(latitude, longitude);
	return coords;
}

// Returns CLLocation object
- (CLLocation *) getLocation {
	CLLocationCoordinate2D coords = [self getCoordinate];
	NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
	[outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	NSDate *theDate = [outputFormatter dateFromString:self.theTimestamp];
	theLocation = [[CLLocation alloc] initWithCoordinate:coords
							altitude:altitude
				  horizontalAccuracy:horizontalAccuracy
					verticalAccuracy:verticalAccuracy
							  course:course
							   speed:speed
						   timestamp:theDate];
	return theLocation;
}

- (void)dealloc {
    [super dealloc];

    [theTimestamp release];
    [theLocation release];
    
}


@end
