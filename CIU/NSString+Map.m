//
//  NSString+Map.m
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "NSString+Map.h"

@implementation NSString (Map)
+(NSString *)stringFromMKCoordinateRegion:(MKCoordinateRegion)region{
    return [NSString stringWithFormat:@"latitude:%f\nlongitude:%f\nlatitudeDelta:%f\nlongitudeDelta:%f)",region.center.latitude,region.center.longitude,region.span.latitudeDelta,region.span.longitudeDelta];
}
@end
