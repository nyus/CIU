//
//  CommentTableViewCell.m
//  FastPost
//
//  Created by Sihang Huang on 6/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
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
    
    UIBezierPath *circle = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.avatarImageView.frame)/2, CGRectGetHeight(self.avatarImageView.frame)/2)
                                                                radius:self.avatarImageView.frame.size.width/2
                                                            startAngle:0
                                                              endAngle:2*M_PI
                                                             clockwise:YES];
    CAShapeLayer *circularMask = [CAShapeLayer new];
    circularMask.path = circle.CGPath;
    self.avatarImageView.layer.mask = circularMask;
    self.avatarImageView.backgroundColor = [UIColor clearColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
