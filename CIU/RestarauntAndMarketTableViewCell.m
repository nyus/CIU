//
//  RestarauntAndMarketTableViewCell.m
//  DaDa
//
//  Created by Sihang Huang on 8/24/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "RestarauntAndMarketTableViewCell.h"

@implementation RestarauntAndMarketTableViewCell

+ (UIFont *)fontForContent
{
    return [UIFont fontWithName:@"Helvetica-Light" size:12.0];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14.0];
        self.contentLabel.font = [RestarauntAndMarketTableViewCell fontForContent];
        self.phoneTextView.font = [RestarauntAndMarketTableViewCell fontForContent];
    }
    
    return self;
}

@end
