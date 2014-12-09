//
//  GenericTableViewController.h
//  CIU
//
//  Created by Huang, Sihang on 8/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SharedDataManager.h"
#import "Reachability.h"
@interface GenericTableViewController : UITableViewController
{
    @protected
    int _localDataCount;
    int _serverDataCount;
}

-(void)pullDataFromServer;
-(void)pullDataFromLocal;
-(void)loadRemoteDataForVisibleCells;
-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath;
-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
-(void)refreshControlTriggered:(UIRefreshControl *)sender;
-(void)addRefreshControll;
-(void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location;
@end
