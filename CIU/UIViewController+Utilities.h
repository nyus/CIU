//
//  UIViewController+Utilities.h
//  DaDa
//
//  Created by Sihang Huang on 2/4/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (Utilities)

- (void)showReportAlertWithBlock:(void(^)(BOOL yesButtonTapped))block;

@end
