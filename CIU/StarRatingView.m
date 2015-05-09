//
//  StarRatingView.m
//  DaDa
//
//  Created by Sihang on 5/9/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "StarRatingView.h"

static CGFloat const kNumOfStars = 5.0;
static CGFloat const kDegree = 2.0 * M_PI * (2.0 / 5.0); // 144 degrees

@implementation StarRatingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    CGColorRef fillColorRef = [UIColor darkGrayColor].CGColor;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat xCenter = CGRectGetWidth(rect) / kNumOfStars / 2;
    CGFloat yCenter = CGRectGetHeight(rect) / 2;
    CGFloat xCenterStep = CGRectGetWidth(rect) / kNumOfStars;
    
    CGFloat radius = CGRectGetWidth(rect) / kNumOfStars / 4.0;
    CGFloat flip = -1.0;
    
    for (NSUInteger i=0; i<kNumOfStars; i++)
    {
        CGContextSetFillColorWithColor(context, fillColorRef);
        CGContextSetStrokeColorWithColor(context, fillColorRef);
        
        CGContextMoveToPoint(context, xCenter, radius*flip+yCenter);
        
        for (NSUInteger k=1; k<kNumOfStars; k++)
        {
            float x = radius * sin(k * kDegree);
            float y = radius * cos(k * kDegree);
            CGContextAddLineToPoint(context, x+xCenter, y*flip+yCenter);
        }
        xCenter += xCenterStep;
    }
    
    CGContextClosePath(context);
    CGContextFillPath(context);
}

@end
