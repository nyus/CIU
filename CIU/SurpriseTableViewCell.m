//
//  StatusTableCell.m
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import <Parse/Parse.h>
#import "SurpriseTableViewCell.h"
#import "ImageCollectionViewCell.h"
#import "Helper.h"
#import "PFFile+Utilities.h"

#define REVIVE_PROGRESS_VIEW_INIT_ALPHA .7f
#define PROGRESSION_RATE 1
#define TRESHOLD 60.0f

static CGFloat const kCollectionCellWidth = 84.0f;
static CGFloat const kCollectionCellHeight = 84.0f;

@interface SurpriseTableViewCell() <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>{
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

- (void)setFilesArray:(NSArray *)collectionViewDataSource
{
    if (_filesArray != collectionViewDataSource) {
        _imagesArray = nil;
        _filesArray = collectionViewDataSource;
        [self.collectionView reloadData];
        [self loadImages];
    }
}

- (void)setImagesArray:(NSArray *)imagesArray
{
    if (_imagesArray != imagesArray) {
        _filesArray = nil;
        _imagesArray = imagesArray;
        [self.collectionView reloadData];
    }
}

- (void)loadImages
{
    int i = 0;
    NSMutableDictionary *dictionary;
    for (PFFile *file in self.filesArray) {
        
        if (file.isDataAvailable) {
            continue;
        }
        
        if (!dictionary) {
            dictionary = [NSMutableDictionary dictionaryWithCapacity:self.filesArray.count];
        }
        
        dictionary[file.name] = @(i);
        [file fetchImageWithCompletionBlock:^(BOOL completed, NSData *data) {
            
            if (completed) {
                NSNumber *count = dictionary[file.name];
                [Helper saveImageToLocal:data
                            forImageName:FSTRING(@"%@%d", self.statusPhotoId, [dictionary[file.name] intValue])
                               isHighRes:NO];
                [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:count.integerValue
                                                                                  inSection:0]]];
            }
        }];
        i++;
    }
}

- (UIImage *)imageForCellAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image;
    
    if (self.filesArray) {
        PFFile *file = self.filesArray[indexPath.row];
        
        if (file.isDataAvailable) {
            image = [UIImage imageWithData:file.getData];
        }
    } else if (self.imagesArray) {
        image = self.imagesArray[indexPath.row];
    }
    
    return image;
}

#pragma mark - uicollectionview delegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return self.filesArray ? self.filesArray.count : self.imagesArray.count;
}

-(ImageCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
//    return [self.delegate surpriseCell:self collectionView:collectionView cellForItemAtIndexPath:indexPath];
    ImageCollectionViewCell *collectionViewCell = (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    // Clear out old image first
    
    collectionViewCell.imageView.image = [self imageForCellAtIndexPath:indexPath];
    
    return collectionViewCell;
}

#pragma mark - uicollectionview flow layout delegate

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    return [self.delegate surpriseCell:self collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath];
    
    if (!self.filesArray && !self.imagesArray) {
        
        return CGSizeMake([ImageCollectionViewCell imageViewWidth], [ImageCollectionViewCell imageViewHeight]);
    }
    
    UIImage *image = [self imageForCellAtIndexPath:indexPath];
    CGFloat width = image.size.width < image.size.height ? [ImageCollectionViewCell imageViewHeight] / image.size.height * image.size.width : [ImageCollectionViewCell imageViewWidth];
    
    return CGSizeMake(width, [ImageCollectionViewCell imageViewHeight]);
}

@end
