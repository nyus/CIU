//
//  ImageCollectionViewCell.h
//  FastPost
//
//  Created by Sihang Huang on 6/21/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

+ (CGFloat)imageViewWidth;
+ (CGFloat)imageViewHeight;

@end
