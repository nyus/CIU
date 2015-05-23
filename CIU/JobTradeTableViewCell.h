//
//  JobTradeTableViewCell.h
//  CIU
//
//  Created by Sihang on 11/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "GenericTableViewCell.h"

@class JobTradeTableViewCell;

@protocol JobTradeTableViewCellDelegate <NSObject>

-(void)flagBadContentButtonTappedOnCell:(JobTradeTableViewCell *)cell;

@end

@interface JobTradeTableViewCell : GenericTableViewCell

+ (UIFont *)fontForContentTextView;
+ (CGFloat)heightForCellWithContentString:(NSString *)contentString cellWidth:(CGFloat)cellWidth;

@property (strong, nonatomic) IBOutlet UIButton *flagButton;
@property (strong, nonatomic) IBOutlet UITextView *contentTextView;
@property (assign, nonatomic) id<JobTradeTableViewCellDelegate>delegate;

@end
