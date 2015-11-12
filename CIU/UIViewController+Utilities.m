//
//  UIViewController+Utilities.m
//  DaDa
//
//  Created by Sihang Huang on 2/4/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "UIViewController+Utilities.h"
#import <Parse/Parse.h>
#import "UIAlertView+Blocks.h"

NSString *const kYesKey = @"Yes";
NSString *const kNoKey = @"No";

@implementation UIViewController (Utilities)

- (void)showReportAlertWithBlock:(void (^)(BOOL))block
{
    [UIAlertView showWithTitle:nil message:@"Report inappropriate information？" cancelButtonTitle:kNoKey otherButtonTitles:@[kYesKey] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:kYesKey]) {
            block(YES);
        } else {
            block(NO);
        }
    }];
}

@end
