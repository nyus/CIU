//
//  NSPredicate+Utilities.m
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "NSPredicate+Utilities.h"
#import "Helper.h"
@implementation NSPredicate (Utilities)
+(NSPredicate *)boudingCoordinatesPredicateForRegion:(MKCoordinateRegion)region{
    CLLocationDegrees latMin = region.center.latitude - .5 * region.span.latitudeDelta;
    CLLocationDegrees latMax = region.center.latitude + .5 * region.span.latitudeDelta;
    CLLocationDegrees lonMin = region.center.longitude - .5 * region.span.longitudeDelta;
    CLLocationDegrees lonMax = region.center.longitude + .5 * region.span.longitudeDelta;
    NSPredicate *prediate = [NSPredicate predicateWithFormat:@"self.latitude<=%f && self.latitude>=%f && self.longitude<= %f && self.longitude >=%f",latMax,latMin,lonMax,lonMin, 1];
    return prediate;
    
}

+(NSPredicate *)geoBoundAndStickyPostPredicateForRegion:(MKCoordinateRegion)region{
    CLLocationDegrees latMin = region.center.latitude - .5 * region.span.latitudeDelta;
    CLLocationDegrees latMax = region.center.latitude + .5 * region.span.latitudeDelta;
    CLLocationDegrees lonMin = region.center.longitude - .5 * region.span.longitudeDelta;
    CLLocationDegrees lonMax = region.center.longitude + .5 * region.span.longitudeDelta;
    NSPredicate *prediate = [NSPredicate predicateWithFormat:@"(self.latitude<=%f && self.latitude>=%f && self.longitude<= %f && self.longitude >=%f) || (self.isStickyPost.intValue == %d)",latMax,latMin,lonMax,lonMin, 1];
    return prediate;
    
}

/*
 distance: unit is mile
 */
+(NSPredicate *)boundingCoordinatesToCenter:(CLLocationCoordinate2D)center radius:(NSNumber *)radius{
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:radius];
    return [NSPredicate boudingCoordinatesPredicateForRegion:region];
}
@end
