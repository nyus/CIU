//
//  UIViewController+EULA.h
//  DaDa
//
//  Created by Sihang on 4/3/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EulaVC.h"

@interface UIViewController (EULA) <EulaVCDelegate>

- (void)showEULA;
- (void)logInWithFB;

@end
