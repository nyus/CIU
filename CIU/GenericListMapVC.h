//
//  GenericListMapVC.h
//  DaDa
//
//  Created by Sihang on 9/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "GenericTableVC.h"

@class MKMapView;

@interface GenericListMapVC : GenericTableVC

@property (strong, nonatomic) MKMapView *mapView;

- (void)handleRedoSearchButtonTapped;

@end
