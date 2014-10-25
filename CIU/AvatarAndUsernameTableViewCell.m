//
//  CommentTableViewCell.m
//  FastPost
//
//  Created by Sihang Huang on 6/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "AvatarAndUsernameTableViewCell.h"

@implementation AvatarAndUsernameTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    
    return self;
}

- (void)avatarImageViewTapped{
    [self.delegate avatarImageViewTappedWithCell:self];
}

- (void)awakeFromNib
{
    // Initialization code
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageViewTapped)];
    [self.avatarImageView addGestureRecognizer:tap];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
