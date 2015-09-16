//
//  JobTradeTableViewCell.m
//  CIU
//
//  Created by Sihang on 11/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Masonry.h"
#import "JobTradeTableViewCell.h"

static CGFloat const kContentTextViewLeadingSpace = 15.0;
static CGFloat const kContentTextViewTopSpace = 10.0;
static CGFloat const kContentTextViewTrailingSpace = 15.0;

static CGFloat const kContentTextViewFlagButtonInterSpace = 10.0;

static CGFloat const kFlagButtonHeight = 37.0;//22.0;
static CGFloat const kFlagButtonWidth = 44.0;//26.0;
static CGFloat const kFlagButtonTrailingSpace = 5.0;
static CGFloat const kFlagButtonBottomSpace = 0.0;

static CGFloat const kDefaultCellHeight = 44.0;

static NSString *const kFlagOnImageName = @"flag_on";

@implementation JobTradeTableViewCell

+ (CGFloat)heightForCellWithContentString:(NSString *)contentString cellWidth:(CGFloat)cellWidth
{
    CGRect rect = [contentString boundingRectWithSize:CGSizeMake(cellWidth - kContentTextViewLeadingSpace - kContentTextViewTrailingSpace, MAXFLOAT)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[JobTradeTableViewCell fontForContentTextView]}
                                              context:NULL];
    
    //40 takes the flag button into consideration. 10 spacing and 22 button height
    if (kContentTextViewTopSpace + rect.size.height + kContentTextViewFlagButtonInterSpace + kFlagButtonHeight < kDefaultCellHeight) {
        
        return kDefaultCellHeight;
    } else {
        
        return kContentTextViewTopSpace + rect.size.height + kContentTextViewFlagButtonInterSpace + kFlagButtonHeight + kFlagButtonBottomSpace;
    }
}

+ (UIFont *)fontForContentTextView
{
    return [UIFont fontWithName:@"Helvetica-Light" size:14.0];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.contentTextView = [UITextView new];
        self.contentTextView.scrollEnabled = NO;
        self.contentTextView.showsHorizontalScrollIndicator = NO;
        self.contentTextView.showsVerticalScrollIndicator = NO;
        self.contentTextView.dataDetectorTypes = UIDataDetectorTypeLink;
        self.contentTextView.editable = NO;
        self.contentTextView.selectable = YES;
        self.contentTextView.font = [UIFont fontWithName:@"Helvetica-Light" size:14.0];
        self.contentTextView.textContainerInset = UIEdgeInsetsZero;
        self.contentTextView.textContainer.lineFragmentPadding = 0;
        [self.contentView addSubview:self.contentTextView];
        
        self.flagButton = [UIButton new];
        [self.flagButton setImage:[UIImage imageNamed:@"flag_off"] forState:UIControlStateNormal];
        [self.flagButton setImage:[UIImage imageNamed:@"flag_on"] forState:UIControlStateDisabled];
        [self.flagButton addTarget:self action:@selector(flagBadContentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.flagButton];
        
        [self setupContraints];
    }
    
    return self;
}

- (void)setupContraints
{
    __weak typeof(self) weakSelf = self;
    [_contentTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@(kContentTextViewLeadingSpace));
        make.trailing.equalTo(@(-kContentTextViewTrailingSpace));
        make.top.equalTo(weakSelf.contentView).offset(kContentTextViewTopSpace);
    }];
    
    [_flagButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(kFlagButtonWidth));
        make.height.equalTo(@(kFlagButtonHeight));
        make.top.equalTo(_contentTextView.mas_bottom).offset(kContentTextViewFlagButtonInterSpace);
        make.trailing.equalTo(weakSelf.contentView).offset(-kFlagButtonTrailingSpace);
    }];
}

- (IBAction)flagBadContentButtonTapped:(id)sender {
    [self.delegate flagBadContentButtonTappedOnCell:self];
}

@end
