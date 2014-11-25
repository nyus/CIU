//
//  JobTradeTableViewCell.h
//  CIU
//
//  Created by Sihang on 11/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "GenericTableViewCell.h"
@class JobTradeTableViewCell;
@protocol JobTradeTableViewCellDelegate <NSObject>

-(void)flagBadContentButtonTappedOnCell:(JobTradeTableViewCell *)cell;

@end

@interface JobTradeTableViewCell : GenericTableViewCell
@property (weak, nonatomic) IBOutlet UIButton *flagButton;
@property (assign, nonatomic) id<JobTradeTableViewCellDelegate>delegate;
@end
