//
//  GenericMapVC.h
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class LifestyleObject;
@class PFQuery;

@interface GenericMapVC : UIViewController

@property (strong, nonatomic) MKMapView *mapView;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;
@property (nonatomic, strong) LifestyleObject *lifestyleToPass;
@property (nonatomic, strong) PFQuery *fetchQuery;
@property (nonatomic, assign) BOOL isInternetPresentOnLaunch;

-(void)fetchServerDataWithRegion:(MKCoordinateRegion)region;

@end
