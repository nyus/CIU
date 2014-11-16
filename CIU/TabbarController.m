//
//  TabbarController.m
//  CIU
//
//  Created by Huang, Jason on 8/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "TabbarController.h"
#import "UIColor+CIUColors.h"
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
    UITabBarItem *item2 = [tabBar.items objectAtIndex:1];
    UITabBarItem *item3 = [tabBar.items objectAtIndex:2];
    
    item1.selectedImage = [[UIImage imageNamed:@"1lifestyle"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item1.image = [[UIImage imageNamed:@"1lifestyle_unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item1 setImageInsets:UIEdgeInsetsMake(5,5,5,5)];

    item2.selectedImage = [[UIImage imageNamed:@"1events"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item2.image = [[UIImage imageNamed:@"1event_unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item2 setImageInsets:UIEdgeInsetsMake(5,5,5,5)];
    
    item3.selectedImage = [[UIImage imageNamed:@"1Surprise"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    item3.image = [[UIImage imageNamed:@"1Surprise_unselected"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [item2 setImageInsets:UIEdgeInsetsMake(5,5,5,5)];
    
}

- (IBAction)menuButtonTapped:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarSlideOpen" object:self];
}

- (void)navBarTapped:(id)sender
{
    [self.tabBarControllerDelegate navigationBarTapped];
}
@end
