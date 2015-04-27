//
//  SignUpViewController.h
//  FastPost
//
//  Created by Sihang Huang on 2/24/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LogInVC;

@interface SignUpVC : UIViewController<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (strong ,nonatomic) LogInVC *loginVC;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)signUpButtonTapped:(id)sender;

@end
