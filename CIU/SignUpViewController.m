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
#import "Helper.h"
@interface SignUpViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
    UIAlertView *signUpSuccessAlert;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageviewTopSpaceToTopLayoutConstraint;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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

- (IBAction)avatarImageViewTapped:(id)sender {
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take A Photo",@"Add From Gallery", nil];
    [actionsheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    //0 take a photo, 1 add from gallery
    
    if (buttonIndex == 0) {
        [self launchCameraPicker];
    }else if (buttonIndex ==1){
        [self launchGalleryPicker];
    }else{

    }
}

- (void) launchCameraPicker {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if (!self.imagePicker) {
            self.imagePicker = [[UIImagePickerController alloc] init];
            self.imagePicker.delegate = self;
        }
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.allowsEditing = NO;
        self.imagePicker.cameraCaptureMode = (UIImagePickerControllerCameraCaptureModePhoto);
    }
}

- (void) launchGalleryPicker {
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
    }
    
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (IBAction)signUpButtonTapped:(id)sender {
    
    //dismiss keyboard
    [self.view endEditing:YES];
    
    if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=20) {
        self.imageviewTopSpaceToTopLayoutConstraint.constant = 20;
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    
    NSString *userNameString =[self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *emailString =[self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *passWordString = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![emailString isEqualToString:@""] && ![userNameString isEqualToString:@""] && ![passWordString isEqualToString:@""]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //spinner starts spinning
            self.activityIndicator.hidden = NO;
            [self.activityIndicator startAnimating];
        });
        
        //
        __block SignUpViewController *weakSelf = self;
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
                [newUser setObject:weakSelf.firstNameTextField.text forKey:@"firstName"];
                [newUser setObject:weakSelf.lastNameTextField.text forKey:@"lastName"];
                
                [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                    if(succeeded){
                        
                        //save avatar to local and server. the reason to do it now is becuase we need to associate the avatar with a username
                        NSData *highResData = UIImagePNGRepresentation(weakSelf.avatarImageView.image);
                        UIImage *scaled = [Helper scaleImage:weakSelf.avatarImageView.image downToSize:weakSelf.avatarImageView.frame.size];
                        NSData *lowResData = UIImagePNGRepresentation(scaled);
                        //save to both local and server
                        [Helper saveAvatar:highResData forUser:userNameString isHighRes:YES];
                        [Helper saveAvatar:lowResData forUser:userNameString isHighRes:NO];
                        
                        //UI work
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.activityIndicator stopAnimating];
                            signUpSuccessAlert = [[UIAlertView alloc] initWithTitle:nil message:@"Congrats! You have successfully signed up!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
                            signUpSuccessAlert.tag = 0;
                            [signUpSuccessAlert show];
                            [weakSelf performSelector:@selector(showStatusTableView) withObject:nil afterDelay:.5];
                        });
                    }else{

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.activityIndicator stopAnimating];
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Sign up failed. Please try again" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                            alert.tag = 1;
                            [alert show];
                        });
                    }
                }];
                
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.activityIndicator stopAnimating];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Email or username is already registered. Please try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                    [alert show];
                });
            }
        }];
    }
}

- (IBAction)backToLoginButtonTapped:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
#warning
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9a-zA-Z._]"];
//    BOOL flag = [predicate evaluateWithObject:string];
//    if (!flag) {
//        return NO;
//    }else{
//        return YES;
//    }
    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == self.emailTextField) {
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=20) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = 20;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if (textField == self.firstNameTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=20) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = 20;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if (textField == self.lastNameTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=20) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = 20;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if (textField == self.usernameTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=0) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = 0;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if(textField == self.passwordTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=-20) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant =-20;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    textField.text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (textField == self.emailTextField) {

        [self.firstNameTextField becomeFirstResponder];
    }else if (textField == self.firstNameTextField){

        [self.lastNameTextField becomeFirstResponder];
    }else if (textField == self.lastNameTextField){

        [self.usernameTextField becomeFirstResponder];
    }else if (textField == self.usernameTextField){
 
        [self.passwordTextField becomeFirstResponder];
    }else if(textField == self.passwordTextField){

        [self signUpButtonTapped:nil];
    }
    
    return NO;
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *original = info[@"UIImagePickerControllerOriginalImage"];
    self.avatarImageView.image = original;
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
