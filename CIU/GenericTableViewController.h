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
@interface GenericTableViewController : UITableViewController
-(void)pullDataFromServer;
-(void)pullDataFromLocal;
-(void)loadRemoteDataForVisibleCells;
-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end
