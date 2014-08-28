//
//  BaseViewControllerWithStatusTableView.h
//  FastPost
//
//  Created by Sihang Huang on 1/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StatusTableViewCell.h"
@class StatusObject;
@interface BaseViewControllerWithStatusTableView : UIViewController<UITableViewDataSource, UITableViewDelegate,StatusTableViewCellDelegate>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
-(void)removeStoredHeightForStatus:(StatusObject *)status;
@end
