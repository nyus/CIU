//
//  LifestyleLevel2Test.m
//  DaDa
//
//  Created by Sihang on 6/27/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KIF.h>
#import "DDAccessibilityLabelConstants.h"
#import "KIFUITestActor+Stepper.h"
#import "KIFUITestActor+SegmentedControl.h"

@interface LifestyleLevel2Test : KIFTestCase

@end

@implementation LifestyleLevel2Test

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRestaurant
{
    // go into category
    [tester tapViewWithAccessibilityLabel:@"Restaurant"];
    // wait for tbview to load data
    [tester waitForViewWithAccessibilityLabel:kTableViewAccessibilityLabel];
    // scroll tabview
    [tester swipeViewWithAccessibilityLabel:kTableViewAccessibilityLabel inDirection:KIFSwipeDirectionUp];
    // change radius
    for (int i = 0; i < 10; i++) {
        [tester tapRightButtonOnStepperWithAccessibilityLabel:kRadiusStepperAccessibilityLabel];
        [tester waitForTimeInterval:2];
    }
    
    for (int i = 0; i < 10; i++) {
        [tester tapLeftButtonOnStepperWithAccessibilityLabel:kRadiusStepperAccessibilityLabel];
        [tester waitForTimeInterval:2];
    }
    // change to map view
    [tester tapItemAtIndex:1 totalItemCount:2 forSegmentedControlWithAccessibilityLabel:kListMapSegmentedControlAccessibilityLabel];
    [tester waitForTimeInterval:3];
    // change to list view
    [tester tapItemAtIndex:0 totalItemCount:2 forSegmentedControlWithAccessibilityLabel:kListMapSegmentedControlAccessibilityLabel];
    [tester waitForTimeInterval:3];
    // go one level up to the main list
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testSupermarket
{

}

- (void)testJobs
{

}

- (void)testTradeAndSell
{

}

@end
