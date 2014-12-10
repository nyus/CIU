//
//  StatusTableCell.m
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "SurpriseTableViewCell.h"
#import "ImageCollectionViewCell.h"
#import <Parse/Parse.h>
#define REVIVE_PROGRESS_VIEW_INIT_ALPHA .7f
#define PROGRESSION_RATE 1
#define TRESHOLD 60.0f
@interface SurpriseTableViewCell(){
    UISwipeGestureRecognizer *leftSwipteGesture;
    UISwipeGestureRecognizer *rightSwipteGesture;
    UITapGestureRecognizer *tap;
    UIPanGestureRecognizer *pan;
    float x;
}

@end

@implementation SurpriseTableViewCell

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
    return self.collectionViewImagesArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ImageCollectionViewCell *cell = (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageView.image = self.collectionViewImagesArray[indexPath.row];
    return cell;
}
@end
