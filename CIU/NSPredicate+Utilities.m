//
//  NSPredicate+Utilities.m
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "NSPredicate+Utilities.h"

@implementation NSPredicate (Utilities)
+(NSPredicate *)boudingCoordinatesPredicateForRegion:(MKCoordinateRegion)region{
    CLLocationDegrees latMin = region.center.latitude - .5 * region.span.latitudeDelta;
    CLLocationDegrees latMax = region.center.latitude + .5 * region.span.latitudeDelta;
    CLLocationDegrees lonMin = region.center.longitude - .5 * region.span.longitudeDelta;
    CLLocationDegrees lonMax = region.center.longitude + .5 * region.span.longitudeDelta;
    NSPredicate *prediate = [NSPredicate predicateWithFormat:@"self.latitude<=%f && self.latitude>=%f && self.longitude<= %f && self.longitude >=%f",latMax,latMin,lonMax,lonMin];
    return prediate;
    
}
@end
