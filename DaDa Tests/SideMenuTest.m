//
//  SideMenuTest.m
//  DaDa
//
//  Created by Sihang on 6/25/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KIF.h>
#import "DDAccessibilityLabelConstants.h"
#import "StartupVC.h"

@interface SideMenuTest : KIFTestCase

@end

@implementation SideMenuTest

- (void)setUp {
    [super setUp];
    
    [tester tapViewWithAccessibilityLabel:kMenuButtonAccessibilityLabel];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1ProfielPicture
{
    // Take a photo
    [tester tapViewWithAccessibilityLabel:kProfileImageViewAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Take A Photo"];
    [tester tapViewWithAccessibilityLabel:kCameraNotSupportedAccessibilityLabel];
    
    // Choose from gallery
    [tester tapViewWithAccessibilityLabel:kProfileImageViewAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Add From Gallery"];
    //[tester acknowledgeSystemAlert];
    [tester choosePhotoInAlbum:@"Saved Photos" atRow:0 column:0];
    [tester tapViewWithAccessibilityLabel:@"Choose"];
    
    // Cancel
    [tester tapViewWithAccessibilityLabel:kProfileImageViewAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)test2TapEachRowInMenu
{
    //[NSArray arrayWithObjects:@"User Profile",@"About",@"Rate",@"Feedback",@"Share",@"Terms & Privacy",@"Log out", nil];
    [tester tapViewWithAccessibilityLabel:@"About"];
    [tester swipeViewWithAccessibilityLabel:@"Scroll View" inDirection:KIFSwipeDirectionUp];
    [tester tapViewWithAccessibilityLabel:@"Done"];
    
    [tester tapViewWithAccessibilityLabel:@"Rate"];
    
    [tester tapViewWithAccessibilityLabel:@"Terms & Privacy"];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
    
    [tester tapViewWithAccessibilityLabel:@"Terms & Privacy"];
    [tester tapViewWithAccessibilityLabel:@"Terms of Use"];
    [tester swipeViewWithAccessibilityLabel:@"Text View" inDirection:KIFSwipeDirectionUp];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester tapViewWithAccessibilityLabel:@"Privacy Policy"];
    [tester swipeViewWithAccessibilityLabel:@"Text View" inDirection:KIFSwipeDirectionUp];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester tapViewWithAccessibilityLabel:@"Licenses and Disclosures"];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];

    [tester tapViewWithAccessibilityLabel:@"Feedback"];
    [tester waitForViewWithAccessibilityLabel:@"Compose Email"];
    [tester tapScreenAtPoint:CGPointMake(35, 46)];

    [tester tapViewWithAccessibilityLabel:@"Share"];
}

@end
