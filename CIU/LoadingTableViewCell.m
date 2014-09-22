//
//  LoadingTableViewCell.m
//  FastPost
//
//  Created by Sihang Huang on 6/15/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "LoadingTableViewCell.h"

@implementation LoadingTableViewCell

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

- (IBAction)browseMoreButtonTapped:(id)sender {
    [self.delegate browseMoreButtonTappedOnCell:self];
}
@end
