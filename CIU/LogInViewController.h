//
//  ViewController.h
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginTextField.h"

@interface LogInViewController : UIViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet LoginTextField *emailOrUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
- (IBAction)logInButtonTapped:(id)sender;
- (IBAction)forgotPasswrodTapped:(id)sender;
@end
