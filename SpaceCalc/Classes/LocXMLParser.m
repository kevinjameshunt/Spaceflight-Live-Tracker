//
//  XMLParser.m
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


#import "LocXMLParser.h"
#import "SpaceCalcAppDelegate.h"
#import "JSON.h"

@implementation LocXMLParser

@synthesize locData;

- (LocXMLParser *) initXMLParser {
	
	[super init];
	
	appDelegate = (SpaceCalcAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	return self;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict {
	
	if([elementName isEqualToString:@"PredUpdate"]) {

	}
	else if([elementName isEqualToString:@"LocUpdate"]) {
		//Initialize the newLocations array
        appDelegate.newLocations = [[NSMutableArray alloc] init];
	}
	else if([elementName isEqualToString:@"LocData"]) {
		
		//Initialize the loc object.
		locData = [[LocationData alloc] initWithLatitude:0 longitude:0];
		
		//Extract the attribute here.
		//[aLocation setID:[[attributeDict objectForKey:@"id"] integerValue]];
		
	} else if([elementName isEqualToString:@"wind"]) {
		
	} else if([elementName isEqualToString:@"predMessage"]) {
		
	} else if([elementName isEqualToString:@"predData"]) {
		appDelegate.mapPoints = [[NSMutableArray alloc] init];
	}
	
	//DebugLog(@"Processing Element: %@", elementName);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	
	if(!currentElementValue)
		currentElementValue = [[NSMutableString alloc] initWithString:string];
	else
		[currentElementValue appendString:string];
	
	//DebugLog(@"Processing Value: %@", currentElementValue);
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	//If we encounter the end of the xml elements save foundLocations array to DB.
	if([elementName isEqualToString:@"LocUpdate"]){
		return;
	} else if([elementName isEqualToString:@"PredUpdate"]){
		return;
	}
	
	//If we encounter the end of the location element, we want to add the object to the arrays
	// and release the object.
	if([elementName isEqualToString:@"LocData"]) {
		[appDelegate.foundLocations addObject:locData];
        [appDelegate.newLocations addObject:locData];
		
		[locData release];
		locData = nil;
	} else if([elementName isEqualToString:@"wind"]) {
        NSArray *stringSplit = [currentElementValue componentsSeparatedByString:@" "];
		appDelegate.windDir = [stringSplit objectAtIndex:1];
        appDelegate.windSpeed = [NSNumber numberWithDouble:[[stringSplit objectAtIndex:3] intValue] * 1.609344]; // mph -> kmh
	} else if([elementName isEqualToString:@"predMessage"]) {
        appDelegate.lastPredMessage = currentElementValue;
        DebugLog(@"%@",currentElementValue);
	} else if([elementName isEqualToString:@"predData"]) {
        SBJSON *jsonWriter = [[SBJSON new] autorelease];
        NSArray *data = [jsonWriter objectWithString:currentElementValue];
        NSArray *stringSplit;
        for (NSString *locStr in data) {
            stringSplit = [locStr componentsSeparatedByString:@","];
            if ([stringSplit count] == 4) {
                CLLocation *theLocation = [[CLLocation alloc] initWithLatitude:[[stringSplit objectAtIndex:1] doubleValue] 
                                                                     longitude:([[stringSplit objectAtIndex:2] doubleValue]-360)];
                [appDelegate.mapPoints addObject:theLocation];
                
                [theLocation release];
            }
        }
        // Get timestamp of final entry (landing time)
        stringSplit = [[data objectAtIndex:0] componentsSeparatedByString:@","];
        NSInteger startTimestamp = [[stringSplit objectAtIndex:0] intValue];
        stringSplit = [[data objectAtIndex:([data count] -2)] componentsSeparatedByString:@","];
        NSInteger endTimestamp = [[stringSplit objectAtIndex:0] intValue];

        if (startTimestamp > 0 && endTimestamp > 0) {
            NSDate *startTime = [[NSDate alloc] initWithTimeIntervalSince1970:startTimestamp];
            NSDate *endTime = [[NSDate alloc] initWithTimeIntervalSince1970:endTimestamp];
            appDelegate.flightTime = [endTime timeIntervalSinceDate:startTime];
            
            [startTime release];
            [endTime release];
        }
            
        
        appDelegate.predComplete = YES;
	} 
	else
		[locData setValue:currentElementValue forKey:elementName];
	
	[currentElementValue release];
	currentElementValue = nil;
}

- (void) dealloc {
	
	// [aLocation release];
	[currentElementValue release];
	[super dealloc];
}

@end
