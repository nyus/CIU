//
//  TabbarController.m
//  CIU
//
//  Created by Huang, Jason on 8/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "TabbarController.h"

@implementation TabbarController
- (IBAction)menuButtonTapped:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarSlideOpen" object:self];
}

@end
