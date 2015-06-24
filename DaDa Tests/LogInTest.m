//
//  LogInTest.m
//  DaDa
//
//  Created by Sihang on 6/23/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "DDAccessibilityLabelConstants.h"

@interface LogInTest : KIFTestCase

@end

@implementation LogInTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testASignInWithUsername
{
    [tester tapViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    [tester clearTextFromFirstResponder];
    [tester enterText:@"jhuang" intoViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kPassWordTextFieldAccessibilityLabel];
    [tester clearTextFromFirstResponder];
    [tester enterTextIntoCurrentFirstResponder:@"123"];
    
    [tester tapViewWithAccessibilityLabel:kRememberMeButtonAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kSignInButtonAccessibilityLabel];
    
    [self logOut];
}

- (void)logOut
{
    // Log out for next round of entering username and password
    
    [tester tapViewWithAccessibilityLabel:kMenuButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kLogOutButtonAccessibilityLabel];
}

- (void)testBWrongUsername
{
    [tester tapViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    [tester clearTextFromFirstResponder];
    [tester enterText:@"!@#!@#!@#" intoViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kPassWordTextFieldAccessibilityLabel];
    [tester clearTextFromFirstResponder];
    [tester enterTextIntoCurrentFirstResponder:@"123"];
    
    [tester tapViewWithAccessibilityLabel:kRememberMeButtonAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kSignInButtonAccessibilityLabel];
    
    // UIAlertView dismiss
    [tester tapViewWithAccessibilityLabel:@"Dismiss"];
}

- (void)testCWrongPassword
{
    [tester tapViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    [tester clearTextFromFirstResponder];
    [tester enterText:@"jhuang" intoViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kPassWordTextFieldAccessibilityLabel];
    [tester clearTextFromFirstResponder];
    [tester enterTextIntoCurrentFirstResponder:@"asdfkajsdfal"];
    
    [tester tapViewWithAccessibilityLabel:kRememberMeButtonAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kSignInButtonAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:@"Dismiss"];
}

- (void)testDSignup
{
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Back"];
}

- (void)testEFBLogin
{
    [tester tapViewWithAccessibilityLabel:kLogInWithFacebookButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kDeclineEULAButtonAccessibilityLabel];
    
    [tester tapViewWithAccessibilityLabel:kLogInWithFacebookButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kAcceptEULAButtonAccessibilityLabel];
}

@end
