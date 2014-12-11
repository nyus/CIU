//
//  AvatarCollectionViewCell.m
//  FastPost
//
//  Created by Sihang Huang on 6/21/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "ImageCollectionViewCell.h"

static CGFloat const kCollectionCellWidth = 204.0f;
static CGFloat const kCollectionCellHeight = 204.0f;

@implementation ImageCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (CGFloat)imageViewWidth
{
    return kCollectionCellWidth;
}

+ (CGFloat)imageViewHeight
{
    return kCollectionCellHeight;
}


@end
