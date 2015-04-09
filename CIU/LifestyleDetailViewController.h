//
//  LifestyleDetailViewController.h
//  CIU
//
//  Created by Huang, Sihang on 8/22/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LifestyleCategory+Utilities.h"

@interface LifestyleDetailViewController : UIViewController
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) DDCategoryType categoryType;

@end
