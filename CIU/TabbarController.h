//
//  TabbarController.h
//  CIU
//
//  Created by Huang, Sihang on 8/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TabbarControllerDelegate
- (void)navigationBarTapped;
@end

@interface TabbarController : UITabBarController
@property (nonatomic, assign) id<TabbarControllerDelegate>tabBarControllerDelegate;
@end
