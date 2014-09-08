//
//  PFQuery+Utilities.m
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "PFQuery+Utilities.h"
#import <Parse/Parse.h>
#import "Helper.h"
@implementation PFQuery (Utilities)

//coordinates of fetched objects would be within the region
-(void)addBoundingCoordinatesConstraintForRegion:(MKCoordinateRegion)region{
    CLLocationDegrees latMin = region.center.latitude - .5 * region.span.latitudeDelta;
    CLLocationDegrees latMax = region.center.latitude + .5 * region.span.latitudeDelta;
    CLLocationDegrees lonMin = region.center.longitude - .5 * region.span.longitudeDelta;
    CLLocationDegrees lonMax = region.center.longitude + .5 * region.span.longitudeDelta;
    [self whereKey:@"latitude" greaterThanOrEqualTo:[NSNumber numberWithDouble:latMin]];
    [self whereKey:@"latitude" lessThanOrEqualTo:[NSNumber numberWithDouble:latMax]];
    [self whereKey:@"longitude" greaterThanOrEqualTo:[NSNumber numberWithDouble:lonMin]];
    [self whereKey:@"longitude" lessThanOrEqualTo:[NSNumber numberWithDouble:lonMax]];
}

/*
 distance: unit is mile
 */
-(void)addBoundingCoordinatesToCenter:(CLLocationCoordinate2D)center{
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center];
    [self addBoundingCoordinatesConstraintForRegion:region];
}

@end
