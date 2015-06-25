//
//  SignUpVCTest.m
//  DaDa
//
//  Created by Sihang on 6/24/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "DDAccessibilityLabelConstants.h"

@interface SignUpVCTest : KIFTestCase

@end

@implementation SignUpVCTest

- (void)setUp {
    [super setUp];
    
    [tester waitForViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1ProfileImage {
    // Take a photo
    [tester tapViewWithAccessibilityLabel:kProfileImageViewAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Take A Photo"];
    [tester tapViewWithAccessibilityLabel:kCameraNotSupportedAccessibilityLabel];
    
    // Choose from gallery
    [tester tapViewWithAccessibilityLabel:kProfileImageViewAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Add From Gallery"];
    [tester acknowledgeSystemAlert];
    [tester choosePhotoInAlbum:@"Saved Photos" atRow:0 column:0];
    [tester tapViewWithAccessibilityLabel:@"Choose"];
    
    // Cancel
    [tester tapViewWithAccessibilityLabel:kProfileImageViewAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)test2CompleteForm {
    
    // first name
    
    [tester tapViewWithAccessibilityLabel:kFirstNameAccessibilityLabel];
    [tester enterText:@"first" intoViewWithAccessibilityLabel:kFirstNameAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester waitForViewWithAccessibilityLabel:@"Empty field not allowed"];
    [tester clearTextFromViewWithAccessibilityLabel:kFirstNameAccessibilityLabel];
    
    // last name
    
    [tester tapViewWithAccessibilityLabel:kLastNameAccessibilityLabel];
    [tester enterText:@"last" intoViewWithAccessibilityLabel:kLastNameAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester waitForViewWithAccessibilityLabel:@"Empty field not allowed"];
    [tester clearTextFromViewWithAccessibilityLabel:kLastNameAccessibilityLabel];
    
    // username
    
    [tester tapViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    [tester enterText:@"username" intoViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester waitForViewWithAccessibilityLabel:@"Empty field not allowed"];
    [tester clearTextFromViewWithAccessibilityLabel:kUserNameTextFieldAccessibilityLabel];
    
    // email
    
    [tester tapViewWithAccessibilityLabel:kEmailAccessibilityLabel];
    [tester enterText:@"email" intoViewWithAccessibilityLabel:kEmailAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester waitForViewWithAccessibilityLabel:@"Empty field not allowed"];
    [tester clearTextFromViewWithAccessibilityLabel:kEmailAccessibilityLabel];
    
    // password

    [tester tapViewWithAccessibilityLabel:kPassWordTextFieldAccessibilityLabel];
    [tester enterText:@"123" intoViewWithAccessibilityLabel:kPassWordTextFieldAccessibilityLabel];
    [tester tapViewWithAccessibilityLabel:kSignUpButtonAccessibilityLabel];
    [tester waitForViewWithAccessibilityLabel:@"Empty field not allowed"];
    [tester clearTextFromViewWithAccessibilityLabel:kPassWordTextFieldAccessibilityLabel];
}

@end
