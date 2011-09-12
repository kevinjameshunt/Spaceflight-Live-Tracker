//
//  SpaceCalcAppDelegate.h
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

@interface SpaceCalcAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *          window;
    UITabBarController *tabBarController;
	NSMutableArray *    foundLocations;
    NSMutableArray *    newLocations;
    NSMutableArray *    mapPoints;
    NSString *          windDir;
    NSNumber *          windSpeed;
    NSString *          currentUUID;
    NSString *          lastPredMessage;
    NSInteger           flightTime;
    
    bool predComplete;
}

@property (nonatomic, retain) IBOutlet UIWindow *           window;
@property (nonatomic, retain) IBOutlet UITabBarController * tabBarController;
@property (nonatomic, retain) NSMutableArray *              foundLocations;
@property (nonatomic, retain) NSMutableArray *              newLocations;
@property (nonatomic, retain) NSMutableArray *              mapPoints;
@property (nonatomic, retain) NSString *                    windDir;
@property (nonatomic, retain) NSNumber *                    windSpeed;
@property (nonatomic, retain) NSString *                    currentUUID;
@property (nonatomic, retain) NSString *                    lastPredMessage;
@property (nonatomic, readwrite) NSInteger                  flightTime;

@property (nonatomic, readwrite) bool predComplete;

@end
