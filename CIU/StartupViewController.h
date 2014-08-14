//
//  StartupViewController.h
//  CIU
//
//  Created by Huang, Jason on 8/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartupViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewLeadingSpaceConstraint;

@end
