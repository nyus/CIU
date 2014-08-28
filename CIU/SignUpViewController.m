//
//  SignUpViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/24/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "SignUpViewController.h"
#import <Parse/Parse.h>
#import "LogInViewController.h"
#import "FPLogger.h"
@interface SignUpViewController (){
    UIAlertView *signUpSuccessAlert;
}

@end

@implementation SignUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.activityIndicator.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)showStatusTableView{
    //set user on PFInstallation object so that we can send out targeted pushes
    [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
    [[PFInstallation currentInstallation] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            [FPLogger record:@"successfully set PFUser on PFInstallation"];
            NSLog(@"successfully set PFUser on PFInstallation");
        }else{
            [FPLogger record:@"set PFUser on PFInstallation falied"];
            NSLog(@"set PFUser on PFInstallation falied");
        }
        
        [signUpSuccessAlert dismissWithClickedButtonIndex:0 animated:YES];
        [self dismissViewControllerAnimated:NO completion:^{
            [self.loginVC dismissViewControllerAnimated:NO completion:^{
            }];
        }];

    }];
}

- (IBAction)signUpButtonTapped:(id)sender {
    
    
    NSString *userNameString =[self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *emailString =[self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *passWordString = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![emailString isEqualToString:@""] && ![userNameString isEqualToString:@""] && ![passWordString isEqualToString:@""]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //spinner starts spinning
            self.activityIndicator.hidden = NO;
            [self.activityIndicator startAnimating];
        });
        
        //compound query. OR two conditions together
        PFQuery *username = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [username whereKey:@"username" equalTo:userNameString];
        PFQuery *email = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [email whereKey:@"email" equalTo:emailString];
        PFQuery *alreadyExist = [PFQuery orQueryWithSubqueries:@[username,email]];
        
        [alreadyExist getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if (object == nil) {
                //email and username are available
                //hit api and store user info
                PFUser *newUser = [PFUser user];
                newUser.email = emailString;
                newUser.username = userNameString;
                newUser.password = passWordString;

                [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    if(succeeded){
                        
                        [self.activityIndicator stopAnimating];
                        
                        signUpSuccessAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Congrats! You have successfully signed up!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
                        signUpSuccessAlert.tag = 0;
                        [signUpSuccessAlert show];
                        [self performSelector:@selector(showStatusTableView) withObject:nil afterDelay:.5];
                        
                    }else{

                        [self.activityIndicator stopAnimating];
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Sign up failed. Please try again" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                        alert.tag = 1;
                        [alert show];

                    }
                }];
                
            }else{
                
                [self.activityIndicator stopAnimating];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Email or username is already registered. Please try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                [alert show];
            }
        }];
    }
}

- (IBAction)backToLoginButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    if (textField == self.emailTextField) {
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.usernameTextField becomeFirstResponder];
    }else if (textField == self.usernameTextField){
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.passwordTextField becomeFirstResponder];
    }
    else if(textField == self.passwordTextField){
        textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [textField resignFirstResponder];
    }
    
    return NO;
}

@end
