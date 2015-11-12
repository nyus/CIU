//
//  TabbarController.m
//  CIU
//
//  Created by Huang, Sihang on 8/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "TabbarController.h"
@interface TabbarController ()

@end

@implementation TabbarController

- (void)viewDidLoad
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBarTapped:)];
    [self.navigationController.navigationBar addGestureRecognizer:tap];
    
    //set tabbar items
    UITabBar *tabBar = self.tabBar;
    
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], NSForegroundColorAttributeName,
                                                       [UIFont systemFontOfSize:12.0], NSFontAttributeName, nil]
                                             forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor themeGreen], NSForegroundColorAttributeName,
                                                       [UIFont systemFontOfSize:12.0], NSFontAttributeName, nil]
                                             forState:UIControlStateSelected];
    
    UITabBarItem *item1 = [tabBar.items objectAtIndex:0];
    item1.accessibilityLabel = kLifestyleTabBarItemAccessibilityLabel;
    UITabBarItem *item2 = [tabBar.items objectAtIndex:1];
    item2.accessibilityLabel = kEventsTabBarItemAccessibilityLabel;
    UITabBarItem *item3 = [tabBar.items objectAtIndex:2];
    item3.accessibilityLabel = kSurpriseTabBarItemAccessibilityLabel;
    
    item1.selectedImage = [[UIImage imageNamed:@"lifestyleIcon_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item1.image = [[UIImage imageNamed:@"lifestyleIcon_unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item1.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    item2.selectedImage = [[UIImage imageNamed:@"1event_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item2.image = [[UIImage imageNamed:@"1event_unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item2.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    item3.selectedImage = [[UIImage imageNamed:@"surprise_selected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item3.image = [[UIImage imageNamed:@"surprise_unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item3.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
}

- (IBAction)menuButtonTapped:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarSlideOpen" object:self];
}

- (void)navBarTapped:(id)sender
{
    [self.tabBarControllerDelegate navigationBarTapped];
}
@end
