//
//  StatusTableCell.h
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SurpriseTableViewCell;
@class Status;
@class SpinnerImageView;
@protocol StatusTableViewCellDelegate <NSObject>
@optional
-(void)usernameLabelTappedOnCell:(SurpriseTableViewCell *)cell;
-(void)flagBadContentButtonTappedOnCell:(SurpriseTableViewCell *)cell;
-(void)commentButtonTappedOnCell:(SurpriseTableViewCell *)cell;
-(void)reviveAnimationDidEndOnCell:(SurpriseTableViewCell *)cell withProgress:(float)percentage;
-(void)swipeGestureRecognizedOnCell:(SurpriseTableViewCell *)cell;
@end

@interface SurpriseTableViewCell : UITableViewCell<UICollectionViewDataSource>{
}
@property (strong,nonatomic) Status *status;
@property (assign, nonatomic) id<StatusTableViewCellDelegate>delegate;
@property (weak, nonatomic) IBOutlet UILabel *statusCellMessageLabel;
@property (weak, nonatomic) IBOutlet SpinnerImageView *statusCellPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusCellUsernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCellDateLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusCellAvatarImageView;
@property (weak, nonatomic) IBOutlet UIView *reviveProgressView;
@property (weak, nonatomic) IBOutlet UILabel *reviveCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *userNameButton;
@property (weak, nonatomic) IBOutlet UIButton *commentButton;
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *contentContainerView;
@property (weak, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) NSMutableArray *collectionViewImagesArray;
@property (weak, nonatomic) IBOutlet UIButton *flagButton;
- (IBAction)flagBadContentButtonTapped:(id)sender;
- (IBAction)commentButtonTapped:(id)sender;
@end
