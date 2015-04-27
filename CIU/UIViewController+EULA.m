//
//  UIViewController+EULA.m
//  DaDa
//
//  Created by Sihang on 4/3/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "UIViewController+EULA.h"

@implementation UIViewController (EULA)

- (void)showEULA
{
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"eula"];
    for (EulaVC *vc in nav.viewControllers) {
        if ([vc isKindOfClass:[EulaVC class]]) {
            vc.delegate = self;
        }
    }
    [self presentViewController:nav animated:YES completion:nil];
}

@end
