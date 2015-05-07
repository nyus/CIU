//
//  NameAddressTableViewCell.m
//  DaDa
//
//  Created by Sihang Huang on 5/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "NameAddressTableViewCell.h"

static CGFloat const kLeftSpace = 16.0;
static CGFloat const kNameLabelTopSpace = 20.0;
static CGFloat const kAddressLabelTopSpace = 10.0;
static CGFloat const kAddressLabelBottomSpace = 8.0;

@implementation NameAddressTableViewCell

+ (CGFloat)heightForCellWithName:(NSString *)name address:(NSString *)address cellWidth:(CGFloat)cellWidth
{
    CGRect nameRect = [name boundingRectWithSize:CGSizeMake(cellWidth, MAXFLOAT)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]]}
                                         context:nil];
    
    CGRect addressRect = [address boundingRectWithSize:CGSizeMake(cellWidth, MAXFLOAT)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:[UIFont systemFontSize]]}
                                               context:nil];
    
    return kNameLabelTopSpace + CGRectGetHeight(nameRect) + kAddressLabelTopSpace + CGRectGetHeight(addressRect) + kAddressLabelBottomSpace;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _nameLabel = [UILabel new];
        [self.contentView addSubview:_nameLabel];
        
        _addressLabel = [UILabel new];
        [self.contentView addSubview:_addressLabel];
        
        [self setupConstraints];
    }
    
    return self;
}

- (void)setupConstraints
{
    // Name label
    
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"H:|-(%f)-[_nameLabel]-(%f)-|", kLeftSpace, kLeftSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_nameLabel)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"V:|-(%f)-[_nameLabel]", kNameLabelTopSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_nameLabel)]];
    
    // Address label
    
    _addressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"H:|-(%f)-[_addressLabel]-(%f)-|", kLeftSpace, kLeftSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_addressLabel)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"V:[_nameLabel]-(%f)-[_addressLabel]", kAddressLabelTopSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_nameLabel,_addressLabel)]];
    
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
