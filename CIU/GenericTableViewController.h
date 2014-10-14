//
//  GenericTableViewController.h
//  CIU
//
//  Created by Huang, Jason on 8/15/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SharedDataManager.h"
#import "Reachability.h"
@interface GenericTableViewController : UITableViewController
//@property (nonatomic, strong) UIRefreshControl *refreshControl;
-(void)pullDataFromServer;
-(void)pullDataFromLocal;
-(void)loadRemoteDataForVisibleCells;
-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath;
-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
-(void)refreshControlTriggered:(UIRefreshControl *)sender;
-(void)addRefreshControll;
@end
