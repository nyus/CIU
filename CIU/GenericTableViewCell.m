//
//  GenericTableViewCell.m
//  CIU
//
//  Created by Sihang on 8/24/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "GenericTableViewCell.h"

@implementation GenericTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
