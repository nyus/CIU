//
//  SpinnerImageView.h
//  FastPost
//
//  Created by Sihang Huang on 6/19/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpinnerImageView : UIImageView
@property (nonatomic) UIActivityIndicatorView *spinner;
-(void)showLoadingActivityIndicator;
-(void)hideLoadingActivityIndicator;
@end
