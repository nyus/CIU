//
//  GenericListMapVC.h
//  DaDa
//
//  Created by Sihang on 9/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "GenericTableVC.h"
#import "CustomMKPointAnnotation.h"

@class MKMapView;

@interface GenericListMapVC : GenericTableVC <MKMapViewDelegate>

@property (strong, nonatomic) MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;

- (void)handleRedoSearchButtonTapped;
- (void)fetchLocalDataWithRegion:(MKCoordinateRegion)region;
- (void)fetchServerDataWithRegion:(MKCoordinateRegion)region;

@end
