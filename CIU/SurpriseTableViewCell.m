//
//  StatusTableCell.m
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "SurpriseTableViewCell.h"
#import <Parse/Parse.h>
#define REVIVE_PROGRESS_VIEW_INIT_ALPHA .7f
#define PROGRESSION_RATE 1
#define TRESHOLD 60.0f

static CGFloat const kCollectionCellWidth = 84.0f;
static CGFloat const kCollectionCellHeight = 84.0f;

@interface SurpriseTableViewCell() <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>{
    UISwipeGestureRecognizer *leftSwipteGesture;
    UISwipeGestureRecognizer *rightSwipteGesture;
    UITapGestureRecognizer *tap;
    UIPanGestureRecognizer *pan;
    float x;
}

@end

@implementation SurpriseTableViewCell

+ (CGFloat)imageViewWidth
{
    return kCollectionCellWidth;
}

+ (CGFloat)imageViewHeight
{
    return kCollectionCellHeight;
}

- (void)awakeFromNib
{
    self.collectionView.dataSource  = self;
    self.collectionView.delegate = self;
    self.statusCellAvatarImageView.layer.masksToBounds = YES;
    self.statusCellAvatarImageView.layer.cornerRadius = 30;
}

- (IBAction)flagBadContentButtonTapped:(id)sender {
    [self.delegate flagBadContentButtonTappedOnCell:self];
}

- (IBAction)commentButtonTapped:(id)sender {
    [self.delegate commentButtonTappedOnCell:self];
}

-(void)enableButtonsOnCell:(BOOL)enable{
    self.avatarButton.userInteractionEnabled = enable;
    self.userNameButton.userInteractionEnabled = enable;
    self.commentButton.userInteractionEnabled = enable;
}

#pragma mark - uicollectionview delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [self.delegate surpriseCell:self collectionView:collectionView numberOfItemsInSection:section];
}

-(ImageCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    return [self.delegate surpriseCell:self collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

#pragma mark - uicollectionview flow layout delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate surpriseCell:self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
}
@end
