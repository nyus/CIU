//
//  JobTradeTableViewCell.m
//  CIU
//
//  Created by Sihang on 11/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "JobTradeTableViewCell.h"

@implementation JobTradeTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (IBAction)flagBadContentButtonTapped:(id)sender {
    [self.delegate flagBadContentButtonTappedOnCell:self];
}

@end
