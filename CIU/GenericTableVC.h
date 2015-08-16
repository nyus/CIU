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

@interface GenericTableVC : UITableViewController
{
    @protected
    NSUInteger _localDataCount;
    NSUInteger _serverDataCount;
}

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) PFQuery *fetchQuery;

-(void)pullDataFromServer;
-(void)pullDataFromLocal;
-(NSArray *)pullDataFromLocalWithEntityName:(NSString *)entityName fetchLimit:(NSUInteger)fetchLimit fetchRadius:(CGFloat)fetchRadius;
-(void)loadRemoteDataForVisibleCells;
-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath;
-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
-(void)refreshControlTriggered:(UIRefreshControl *)sender;
-(void)addRefreshControll;
-(void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location;

@end
