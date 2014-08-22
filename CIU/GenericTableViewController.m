//
//  GenericTableViewController.m
//  CIU
//
//  Created by Huang, Jason on 8/15/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "GenericTableViewController.h"
@interface GenericTableViewController()<UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate>
@end
@implementation GenericTableViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self pullDataFromLocal];
    [self pullDataFromServer];
}

-(void)pullDataFromLocal{
    //override by subclass
}

-(void)pullDataFromServer{
    //override by subclass
}

-(void)loadRemoteDataForVisibleCells{
    //override by subclass
}

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{
    //override by subclass
}

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    [self cancelRequestsForIndexpath:indexPath];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    [self cancelNetworkRequestForCell:cell atIndexPath:indexPath];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadRemoteDataForVisibleCells];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self loadRemoteDataForVisibleCells];
    }
}

@end
