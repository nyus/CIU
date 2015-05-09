//
//  NameAddressTableViewCell.m
//  DaDa
//
//  Created by Sihang Huang on 5/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "NameAddressTableViewCell.h"
#import "StarRatingView.h"

static CGFloat const kLeftSpace = 16.0;
static CGFloat const kNameLabelTopSpace = 20.0;
static CGFloat const kAddressLabelBottomSpace = 10.0;
static CGFloat const kStarRatingViewWidth = 150.0;
static CGFloat const kStarRatingViewHeight = 20.0;
static CGFloat const kInterViewTopSpace = 10.0;
static CGFloat const kChineseKnowRightSpace = 5.0;
static CGFloat const kBookmarkRightSpace = 20.0;
static NSString *const kChineseKnotAssetName = @"chineseKnot";
static NSString *const kBookmarkAssetName = @"bookmark";

@interface NameAddressTableViewCell ()

@property (nonatomic, strong) StarRatingView *starRatingView;
@property (nonatomic, strong) UIImageView *bookmark;
@property (nonatomic, strong) UIImageView *chineseKnot;

@end

@implementation NameAddressTableViewCell

+ (CGFloat)heightForCellWithName:(NSString *)name address:(NSString *)address cellWidth:(CGFloat)cellWidth
{
    CGRect nameRect = [name boundingRectWithSize:CGSizeMake(cellWidth, MAXFLOAT)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Bold" size:9.5]}
                                         context:nil];
    
    CGRect addressRect = [address boundingRectWithSize:CGSizeMake(cellWidth, MAXFLOAT)
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:@{NSFontAttributeName : [UIFont fontWithName:@"Helvetica-Light" size:8.5]}
                                               context:nil];
    
    return kNameLabelTopSpace + CGRectGetHeight(nameRect) + kInterViewTopSpace + kStarRatingViewHeight + kInterViewTopSpace + CGRectGetHeight(addressRect) + kAddressLabelBottomSpace;
}

- (void)setIsAuthetic:(BOOL)isAuthetic
{
    if (_isAuthetic != isAuthetic) {
        _isAuthetic = isAuthetic;
    }
    
    _chineseKnot.hidden = !isAuthetic;
}

- (void)setIsVerified:(BOOL)isVerified
{
    if (_isVerified != isVerified) {
        _isVerified = isVerified;
    }
    
    _bookmark.hidden = !isVerified;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        _nameLabel = [UILabel new];
        _nameLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:9.5];
        [self.contentView addSubview:_nameLabel];
        
        _starRatingView = [StarRatingView new];
        [self.contentView addSubview:_starRatingView];
        
        _addressLabel = [UILabel new];
        _addressLabel.font = [UIFont fontWithName:@"Helvetica-Light" size:8.5];
        [self.contentView addSubview:_addressLabel];
        
        _chineseKnot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kChineseKnotAssetName]];
        [self.contentView addSubview:_chineseKnot];
        
        _bookmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:kBookmarkAssetName]];
        [self.contentView addSubview:_bookmark];
        
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
    
    // Star Rating
    _starRatingView.translatesAutoresizingMaskIntoConstraints = NO;
    // - 6.0 is more of a hack to align the first start with the labels
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"H:|-(%f)-[_starRatingView(%f)]", kLeftSpace - 6.0, kStarRatingViewWidth)
                                                                            options:kNilOptions
                                                                            metrics:nil
                                                                              views:NSDictionaryOfVariableBindings(_starRatingView)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"V:[_nameLabel]-(%f)-[_starRatingView(%f)]", kInterViewTopSpace, kStarRatingViewHeight)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_nameLabel,_starRatingView)]];
    
    // Address label
    
    _addressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"H:|-(%f)-[_addressLabel]-(%f)-|", kLeftSpace, kLeftSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_addressLabel)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"V:[_starRatingView]-(%f)-[_addressLabel]", kInterViewTopSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_starRatingView,_addressLabel)]];
    
    // Chinese know
    _chineseKnot.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"H:[_chineseKnot]-(%f)-[_bookmark]", kChineseKnowRightSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_chineseKnot, _bookmark)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"V:|-(0.0)-[_chineseKnot]")
                                                                             options:kNilOptions 
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_chineseKnot)]];
    
    // Bookmark
    _bookmark.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"H:[_bookmark]-(%f)-|", kBookmarkRightSpace)
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_bookmark)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:FSTRING(@"V:|-(0.0)-[_bookmark]")
                                                                             options:kNilOptions
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(_bookmark)]];
    
}

@end
