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
@class DisplayPeripheralHeaderView;

@interface GenericListMapVC : GenericTableVC <MKMapViewDelegate> {
    DisplayPeripheralHeaderView *_headerView;
}

@property (strong, nonatomic) MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;
@property (nonatomic, strong) LifestyleObject *lifestyleToPass;
@property (nonatomic, strong) DisplayPeripheralHeaderView *headerView;

- (void)handleRedoSearchButtonTapped;
- (void)fetchLocalDataWithRegion:(MKCoordinateRegion)region;
- (void)fetchServerDataWithRegion:(MKCoordinateRegion)region;
- (NSString *)lifestyleObjectCategory;

@end
