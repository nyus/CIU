//
//  ViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "LogInViewController.h"
#import <Parse/Parse.h>
#import "SignUpViewController.h"
@interface LogInViewController ()<UIAlertViewDelegate>

@end

@implementation LogInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.activityIndicator.hidden = YES;
    self.title = @"dwndlr";
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    PFUser *user = [PFUser currentUser];
    if (user && user.isAuthenticated) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logInButtonTapped:(id)sender {
    
    [self.view endEditing:YES];
    
    if (![[self.emailOrUsernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] &&
        ![[self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        
        //spinner starts spinning
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        
        //hit api and store user info
        if ([self.emailOrUsernameTextField.text rangeOfString:@"@"].location == NSNotFound) {
            
            //username to log in
            [PFUser logInWithUsernameInBackground:self.emailOrUsernameTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
                if (!error) {
                    [self showStatusTableView];
                }else{
                    [self showIncorrectPasswordOrFieldWithName:@"username"];
                }
                
                [self.activityIndicator stopAnimating];
            }];
        }else{
            //email to log in
            PFQuery *query = [PFQuery queryWithClassName:[PFUser parseClassName]];
            [query whereKey:@"email" equalTo:self.emailOrUsernameTextField.text];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error && object) {
                    [PFUser logInWithUsernameInBackground:object[@"username"] password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
                        if (!error) {
                            [self showStatusTableView];
                        }else{
                            [self showIncorrectPasswordOrFieldWithName:@"email"];
                        }
                    }];

                }else{
                    [self showIncorrectPasswordOrFieldWithName:@"email"];
                }
                
                [self.activityIndicator stopAnimating];
            }];
        }

    }else{
        //invalid input
        //pop up alert
    }
}

-(void)showIncorrectPasswordOrFieldWithName:(NSString *)wrongFieldName{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Incorrect %@ or password, please retry",wrongFieldName] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alert show];
    
}

- (IBAction)signUpButtonTapped:(id)sender {
    
    SignUpViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"signUpVC"];
    vc.loginVC = self;
    [self presentViewController:vc animated:YES completion:nil];

}

- (IBAction)forgotPasswrodTapped:(id)sender {
    UIAlertView *input = [[UIAlertView alloc] initWithTitle:nil message:@"Enter your email to reset password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset", nil];
    input.alertViewStyle = UIAlertViewStylePlainTextInput;
    [input show];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

}

#pragma mark - ui text field delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    if (textField == self.emailOrUsernameTextField) {
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.passwordTextField becomeFirstResponder];
    }else if(textField == self.passwordTextField){
//        [self animateMoveViewDown];
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [textField resignFirstResponder];
    }
    
    return NO;
}

-(void)showStatusTableView{
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - UIAlertView

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        
        BOOL regexPassed = [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\..+"] evaluateWithObject:[alertView textFieldAtIndex:0].text];

        if (!regexPassed){
            return;
        }
        
        [PFUser requestPasswordResetForEmailInBackground:[alertView textFieldAtIndex:0].text block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                
            }else{
                NSLog(@"password reset failed");
            }
        }];
    }
}

@end
