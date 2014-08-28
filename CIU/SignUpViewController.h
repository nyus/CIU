//
//  SignUpViewController.h
//  FastPost
//
//  Created by Sihang Huang on 2/24/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LogInViewController;
@interface SignUpViewController : UIViewController<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong ,nonatomic) LogInViewController *loginVC;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)signUpButtonTapped:(id)sender;
- (IBAction)backToLoginButtonTapped:(id)sender;
@end
