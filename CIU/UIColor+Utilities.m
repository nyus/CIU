//
//  UIColor+Utilities.m
//  DaDa
//
//  Created by Sihang on 5/23/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "UIColor+Utilities.h"

@implementation UIColor (Utilities)

#define UIRGBColor(r, g, b, alpha) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:alpha]

+ (UIColor *)primaryColorWithAlpha:(CGFloat)alpha
{
    return [UIColor primaryColorWithAlpha:alpha];
}

+ (UIColor *)primaryColor
{
    return [UIColor colorWithRed:163.0 / 255.0 green:222.0 / 255.0 blue:221.0 / 255.0 alpha:1.0];
}

@end
