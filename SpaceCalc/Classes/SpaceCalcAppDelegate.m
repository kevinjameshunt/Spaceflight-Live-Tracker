//
//  SpaceCalcAppDelegate.m
//  SpaceCalc 1.0
//
//  Near Space Balloon Tracker V 1.0
//
//  Created by Kevin Hunt on 11-02-10.
//  Copyright 2011 Kevin James Hunt. All rights reserved.
//  kevinjameshunt@gmail.com
//  http://www.kevinjameshunt.com
//

#import "SpaceCalcAppDelegate.h"


@implementation SpaceCalcAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize foundLocations, newLocations, mapPoints;
@synthesize windDir, windSpeed, currentUUID, lastPredMessage, predComplete, flightTime;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
	self.foundLocations = [[NSMutableArray alloc] init];
    self.newLocations = [[NSMutableArray alloc] init];
    //self.mapPoints = [[NSMutableArray alloc] init];
    self.predComplete = NO;
    lastPredMessage = @"";
	
    // Add the tab bar controller's view to the window and display.
    [window addSubview:tabBarController.view];
    [window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {

}


- (void)applicationDidEnterBackground:(UIApplication *)application {

}


- (void)applicationWillEnterForeground:(UIApplication *)application {

}


- (void)applicationDidBecomeActive:(UIApplication *)application {

}


- (void)applicationWillTerminate:(UIApplication *)application {

}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {

}


- (void)dealloc {
    [newLocations release];
    [foundLocations release];
    [mapPoints release];
    [tabBarController release];
    [window release];
    [windDir release];
    [windSpeed release];
    [currentUUID release];
    [super dealloc];
}

@end

