//
//  ViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 11/25/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "LogInVC.h"
#import <Parse/Parse.h>
#import "SignUpVC.h"
#import "Helper.h"
#import "UIResponder+Utilities.h"
#import "UIViewController+EULA.h"

@interface LogInVC () <UIAlertViewDelegate>

@end

@implementation LogInVC

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

- (IBAction)loginWithFBTapped:(id)sender
{
    [self showEULA];
}

#pragma mark - EULADelegate

- (void)acceptedEULAOnVC:(EulaVC *)vc
{
    [vc dismissViewControllerAnimated:YES completion:^{
        [self logInUser];
    }];
}

- (void)logInUser
{
    // Utilize Parse.com SDK
    
    [self.activityIndicator startAnimating];
    __weak typeof(self) weakSelf = self;
    
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"public_profile"];
    
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        
        if (!user) {
            [self.activityIndicator stopAnimating];
            
            if (!error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"You've cancelled the Facebook login."
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
                [alert show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"Something went wrong, please try again"
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"Dismiss", nil];
                [alert show];
            }
            
        } else {
            
            FBRequest *request = [FBRequest requestForMe];
            [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                
                if (error) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"Something went wrong, please try again"
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"Dismiss", nil];
                    [alert show];
                } else {
                    NSDictionary *userData = (NSDictionary *)result;
                    NSString *facebookID = userData[@"id"];
                    NSString *firstName = userData[@"first_name"];
                    NSString *lastName = userData[@"last_name"];
                    NSString *gender = userData[@"gender"];
                    NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
                    
                    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
                    [NSURLConnection sendAsynchronousRequest:urlRequest
                                                       queue:[NSOperationQueue mainQueue]
                                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                               if (!connectionError && data) {
                                                   [Helper saveAvatar:data forUser:user.username isHighRes:YES];
                                                   UIImage *scaledImage = [Helper scaleImage:[UIImage imageWithData:data] downToSize:CGSizeMake(70, 70)];
                                                   [Helper saveAvatar:UIImagePNGRepresentation(scaledImage) forUser:user.username isHighRes:NO];
                                                   [[NSNotificationCenter defaultCenter] postNotificationName:@"downloadFacebookProfilePicComplete" object:nil];
                                               }
                                           }];
                    
                    PFUser *me = [PFUser currentUser];
                    if (facebookID) {
                        [me setObject:facebookID forKey:@"facebookID"];
                    }
                    if (firstName) {
                        [me setObject:firstName forKey:@"firstName"];
                    }
                    if (lastName) {
                        [me setObject:lastName forKey:@"lastName"];
                    }
                    if (gender) {
                        [me setObject:gender forKey:@"gender"];
                    }
                    me[DDIsAdminKey] = @NO;
                    me[DDIsFacebookUserKey] = @YES;
                    [me saveEventually:^(BOOL succeeded, NSError *error) {
                        if(succeeded){
                            //set user on PFInstallation object so that we can send out targeted pushes
                            [FPLogger record:[NSString stringWithFormat:@"Log in VC:FB call storeUserOnInstallation with user:%@",me]];
                            [self storeUserOnInstallation:me];
                        }
                    }];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissLogin" object:nil];
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                }
                
                [self.activityIndicator stopAnimating];
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
            [self loginUserWithUsername:self.emailOrUsernameTextField.text password:self.passwordTextField.text incorrectFieldName:@"username"];
        }else{
            //email to log in
            PFQuery *query = [PFQuery queryWithClassName:[PFUser parseClassName]];
            [query whereKey:@"email" equalTo:self.emailOrUsernameTextField.text];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (!error && object) {
                    [self loginUserWithUsername:object[@"username"] password:self.passwordTextField.text incorrectFieldName:@"email"];
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

- (void)loginUserWithUsername:(NSString *)username password:(NSString *)password incorrectFieldName:(NSString *)incorrectFieldName
{
    [PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
        
        if (!error) {
            [FPLogger record:[NSString stringWithFormat:@"Log in VC:Account call storeUserOnInstallation with user:%@",user]];
            [self storeUserOnInstallation:user];
            [self showStatusTableView];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissLogin" object:nil];
        }else{
            [self showIncorrectPasswordOrFieldWithName:incorrectFieldName];
        }
        
        [self.activityIndicator stopAnimating];
    }];
}

- (void)handleUserLogIn:(PFUser *)user
{
    [self storeUserOnInstallation:user];
    [self showStatusTableView];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissLogin" object:nil];
}

-(void)showIncorrectPasswordOrFieldWithName:(NSString *)wrongFieldName{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"Incorrect %@ or password, please retry",wrongFieldName] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
    [alert show];
    
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
