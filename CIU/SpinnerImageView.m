//
//  SpinnerImageView.m
//  FastPost
//
//  Created by Sihang Huang on 6/19/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "SpinnerImageView.h"

@implementation SpinnerImageView

-(void)setImage:(UIImage *)image{
    [super setImage:image];
    [self hideLoadingActivityIndicator];
}

-(void)showLoadingActivityIndicator{
    if (self.spinner==nil) {
        //add spinner on image view to indicate pulling image
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner.center = CGPointMake((int)self.frame.size.width/2, (int)self.frame.size.height/2);
        self.spinner.hidesWhenStopped = YES;
        [self addSubview:self.spinner];
    }
    [self.spinner startAnimating];
}

-(void)hideLoadingActivityIndicator{
    [self.spinner stopAnimating];
}
@end
