//
//  CommentStatusViewController.h
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class StatusTableViewCell;
@class StatusViewController;
@interface CommentStatusViewController : UIViewController
@property (nonatomic, strong) NSString *statusObjectId;
@property (nonatomic) CGRect animateEndFrame;
@property (weak, nonatomic) StatusTableViewCell *statusTBCell;
@property (weak, nonatomic) StatusViewController *statusVC;
-(void)clearCommentTableView;
- (void)updateCommentCountWithBlock:(void(^)())completion;
@end
