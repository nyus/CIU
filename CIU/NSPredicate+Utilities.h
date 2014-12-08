//
//  NSPredicate+Utilities.h
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@interface NSPredicate (Utilities)
+(NSPredicate *)boudingCoordinatesPredicateForRegion:(MKCoordinateRegion)region;
+(NSPredicate *)boundingCoordinatesToCenter:(CLLocationCoordinate2D)center radius:(NSNumber *)radius;
@end
