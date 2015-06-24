//
//  SignUpTest.swift
//  DaDa
//
//  Created by Sihang Huang on 6/24/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

import UIKit
import XCTest

class SignUpTest: KIFTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tester().waitForViewWithAccessibilityLabel(kSignUpButtonAccessibilityLabel)
        tester().tapViewWithAccessibilityLabel(kSignUpButtonAccessibilityLabel)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test1ProfileImage() {
        // Take a photo
        tester().tapViewWithAccessibilityLabel(kProfileImageViewAccessibilityLabel)
        tester().tapViewWithAccessibilityLabel("Take A Photo")
        tester().tapViewWithAccessibilityLabel("Dismiss")
        
        // Choose from gallery
        tester().tapViewWithAccessibilityLabel(kProfileImageViewAccessibilityLabel)
        tester().tapViewWithAccessibilityLabel("Add From Gallery")
        tester().acknowledgeSystemAlert()
        tester().choosePhotoInAlbum("Camera Roll", atRow: 0, column: 0)
        tester().tapViewWithAccessibilityLabel("Choose")
        
        // Cancel
        tester().tapViewWithAccessibilityLabel(kProfileImageViewAccessibilityLabel)
        tester().tapViewWithAccessibilityLabel("Cancel")
    }
    
    func test2CompleteForm() {
    
    }
}
