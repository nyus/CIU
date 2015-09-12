//
//  ComposeViewController.h
//  CIU
//
//  Created by Huang, Sihang on 9/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LifestyleCategory+Utilities.h"

@interface ComposeJobOrTradeVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic) DDCategoryType categoryType;

@end
