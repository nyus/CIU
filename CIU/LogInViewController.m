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
#import "Helper.h"
@interface LogInViewController ()<UIAlertViewDelegate>

@end

@implementation LogInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.activityIndicator.hidden = YES;
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.backBarButtonItem = nil;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginWithFBTapped:(id)sender {
    
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[ @"user_about_me", @"user_location",@"email"];
    
    [self.activityIndicator startAnimating]; // Show loading indicator until login is finished
    __block LogInViewController *weakSelf = self;
    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        [self.activityIndicator stopAnimating]; // Hide loading indicator
        
        if (!user) {
            NSString *errorMessage = nil;
            if (!error) {
                errorMessage = @"You've cancelled the Facebook login.";
            } else {
                
                FBRequest *request = [FBRequest requestForMe];
                [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        // handle successful response
                    } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                                isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                        NSLog(@"The facebook session was invalidated");
//                        [self logoutButtonAction:nil];
                    } else {
                        NSLog(@"Some other error: %@", error);
                    }
                }];
                
                errorMessage = [error localizedDescription];
            }
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:nil
                                                  otherButtonTitles:@"Dismiss", nil];
            [alert show];
        } else {
            if (user.isNew) {
                NSLog(@"User with facebook signed up and logged in!");
            } else {
                NSLog(@"User with facebook logged in!");
            }
            
            FBRequest *request = [FBRequest requestForMe];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    /*
                     {
                     "first_name" = DrThridteen;
                     gender = male;
                     id = 1529017197309951;
                     "last_name" = Mile;
                     link = "https://www.facebook.com/app_scoped_user_id/1529017197309951/";
                     locale = "en_US";
                     location =     {
                     id = 114586701886732;
                     name = "Detroit, Michigan";
                     };
                     name = "DrThridteen Mile";
                     timezone = "-4";
                     "updated_time" = "2014-09-01T13:53:28+0000";
                     verified = 1;
                     }
                    */
                    // result is a dictionary with the user's Facebook data
                    NSDictionary *userData = (NSDictionary *)result;
                    
                    NSString *facebookID = userData[@"id"];
                    NSString *firstName = userData[@"first_name"];
                    NSString *lastName = userData[@"last_name"];
                    NSString *location = userData[@"location"][@"name"];
                    NSString *gender = userData[@"gender"];
                    NSString *email = userData[@"email"];
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                    
                    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
                    [NSURLConnection sendAsynchronousRequest:urlRequest
                                                       queue:[NSOperationQueue mainQueue]
                                           completionHandler:
                     ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                         if (connectionError == nil && data != nil) {
                             
                             NSLog(@"username %@",user.username);
                             // Set the image in the header imageView
                             [Helper saveAvatar:data forUser:user.username isHighRes:YES];
                             UIImage *scaledImage = [Helper scaleImage:[UIImage imageWithData:data] downToSize:CGSizeMake(70, 70)];
                             [Helper saveAvatar:UIImagePNGRepresentation(scaledImage) forUser:user.username isHighRes:NO];
                         }
                     }];
                    
                    // Now add the data to the UI elements
                    PFUser *me = [PFUser currentUser];
                    [me setObject:facebookID forKey:@"facebookID"];
                    [me setObject:firstName forKey:@"firstName"];
                    [me setObject:lastName forKey:@"lastName"];
                    [me setObject:@YES forKey:@"isFacebookUser"];
                    [me setObject:location forKey:@"location"];
                    [me setObject:email forKey:@"email"];
                    [me setObject:gender forKey:@"gender"];
                    [me saveEventually];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissLogin" object:nil];
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                }
            }];
        }
    }];
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
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissLogin" object:nil];
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please check your email to rest your password." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                    [alert show];
                });
            }else{
                NSLog(@"password reset failed");
            }
        }];
    }
}

@end
