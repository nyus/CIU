//
//  LifestyleTest.m
//  DaDa
//
//  Created by Sihang on 6/25/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KIF.h>
#import "DDAccessibilityLabelConstants.h"

@interface LifestyleTest : KIFTestCase

@end

@implementation LifestyleTest

- (void)setUp {
    [super setUp];
    
    [tester tapViewWithAccessibilityLabel:kLifestyleTabBarItemAccessibilityLabel];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1
{
    [tester tapViewWithAccessibilityLabel:kMenuButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kMenuButtonAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:@"Restaurant"];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester tapViewWithAccessibilityLabel:@"Supermarket"];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester tapViewWithAccessibilityLabel:@"Jobs"];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester tapViewWithAccessibilityLabel:@"Trade and Sell"];
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

@end
