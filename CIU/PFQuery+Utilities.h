//
//  PFQuery+Utilities.h
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Parse/Parse.h>
#import <MapKit/MapKit.h>
@class PFQuery;
@interface PFQuery (Utilities)
-(void)addBoundingCoordinatesConstraintForRegion:(MKCoordinateRegion)region;
-(void)addBoundingCoordinatesToCenter:(CLLocationCoordinate2D)center;
@end
