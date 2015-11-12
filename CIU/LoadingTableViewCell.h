//
//  LoadingTableViewCell.h
//  FastPost
//
//  Created by Sihang Huang on 6/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol LoadingTableViewCellDelegate <NSObject>
@optional
-(void)browseMoreButtonTappedOnCell:(UITableViewCell *)cell;
@end

@interface LoadingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *browseMoreButton;
- (IBAction)browseMoreButtonTapped:(id)sender;
@property (assign, nonatomic) id<LoadingTableViewCellDelegate>delegate;
@end
