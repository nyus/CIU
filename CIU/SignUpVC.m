//
//  SignUpViewController.m
//  FastPost
//
//  Created by Sihang Huang on 2/24/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "SignUpVC.h"
#import <Parse/Parse.h>
#import "LogInVC.h"
#import "Helper.h"
#import "UIResponder+Utilities.h"
#import "UIViewController+EULA.h"

static CGFloat const kViewPositionOriginal = 20;
static CGFloat const kViewPositionMid = 0;
static CGFloat const kViewPositionHigh = -20;

@interface SignUpVC ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate, EulaVCDelegate>{
    UIAlertView *signUpSuccessAlert;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageviewTopSpaceToTopLayoutConstraint;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

@end

@implementation SignUpVC

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

-(void)showStatusTableView{
    
    [FPLogger record:[NSString stringWithFormat:@"SignVC: call storeUserOnInstallation on currentUser:%@", [PFUser currentUser]]];
    [self storeUserOnInstallation:[PFUser currentUser] completion:^(BOOL succeeded, NSError *error) {
        [signUpSuccessAlert dismissWithClickedButtonIndex:0 animated:YES];
    }];
    
    [signUpSuccessAlert dismissWithClickedButtonIndex:0 animated:YES];
    [self dismissViewControllerAnimated:NO completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"dismissLogin" object:nil];
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
    }
}

- (void)launchCameraPicker {
    [Helper launchCameraInController:self];
}

- (void)launchGalleryPicker {
    [Helper launchPhotoLibraryInController:self];
}

- (void)signup
{
    if (self.imageviewTopSpaceToTopLayoutConstraint.constant!=20) {
        self.imageviewTopSpaceToTopLayoutConstraint.constant = 20;
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    
    NSString *userNameString =[self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *emailString =[self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *passWordString = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *firstNameString = [self.firstNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *lastNameString = [self.lastNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![emailString isEqualToString:@""] && ![userNameString isEqualToString:@""] && ![passWordString isEqualToString:@""] && ![lastNameString isEqualToString:@""] && ![firstNameString isEqualToString:@""]) {
        
        //dismiss keyboard
        [self.view endEditing:YES];
        //spinner starts spinning
        self.activityIndicator.hidden = NO;
        [self.activityIndicator startAnimating];
        
        //
        __block SignUpVC *weakSelf = self;
        //compound query. OR two conditions together
        PFQuery *username = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [username whereKey:DDUserNameKey equalTo:userNameString];
        PFQuery *email = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
        [email whereKey:DDEmailKey equalTo:emailString];
        PFQuery *alreadyExist = [PFQuery orQueryWithSubqueries:@[username,email]];
        
        [alreadyExist getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            
            if (object == nil) {
                //email and username are available
                //hit api and store user info
                PFUser *newUser = [PFUser user];
                newUser.email = emailString;
                newUser.username = userNameString;
                newUser.password = passWordString;
                [newUser setObject:weakSelf.firstNameTextField.text forKey:DDFirstNameKey];
                [newUser setObject:weakSelf.lastNameTextField.text forKey:DDLastNameKey];
                [newUser setObject:@NO forKey:DDIsFacebookUserKey];
                [newUser setObject:@NO forKey:DDIsAdminKey];
                
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

- (IBAction)signUpButtonTapped:(id)sender {
    [self showEULA];
}

#pragma mark - EULA Delegate

- (void)acceptedEULAOnVC:(EulaVC *)vc
{
    [vc dismissViewControllerAnimated:YES completion:^{
        [self signup];
    }];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    // Allow backspace
    if ([string isEqualToString:@""]) {
        return YES;
    }

    if (textField == self.passwordTextField) {
        return YES;
    }
    
    NSString *predicateString;
    if (textField == self.emailTextField) {
        predicateString = @"[0-9a-zA-Z._@]";
    } else if (textField != self.passwordTextField){
        predicateString = @"[0-9a-zA-Z._]";
    } else {
        predicateString = nil;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", predicateString];
    BOOL flag = [predicate evaluateWithObject:string];
    if (!flag) {
        return NO;
    }else{
        return YES;
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == self.emailTextField) {
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant != kViewPositionOriginal) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = kViewPositionOriginal;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if (textField == self.firstNameTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant != kViewPositionOriginal) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = kViewPositionOriginal;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if (textField == self.lastNameTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant != kViewPositionOriginal) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = kViewPositionOriginal;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if (textField == self.usernameTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant != kViewPositionMid) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = kViewPositionMid;
            [UIView animateWithDuration:.3 animations:^{
                [self.view layoutIfNeeded];
            }];
        }
    }else if(textField == self.passwordTextField){
        if (self.imageviewTopSpaceToTopLayoutConstraint.constant != kViewPositionHigh) {
            self.imageviewTopSpaceToTopLayoutConstraint.constant = kViewPositionHigh;
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
        
        [self.passwordTextField resignFirstResponder];
        self.imageviewTopSpaceToTopLayoutConstraint.constant = kViewPositionOriginal;
        [UIView animateWithDuration:.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
    
    return NO;
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{

    UIImage *photo = nil;
    if (info[@"UIImagePickerControllerEditedImage"]) {
        [FPLogger record:@"SignupVC: Change avartar to edited image"];
        photo = info[@"UIImagePickerControllerEditedImage"];
    } else if (info[@"UIImagePickerControllerOriginalImage"]){
        [FPLogger record:@"SignupVC: Change avartar to original image"];
        photo = info[@"UIImagePickerControllerOriginalImage"];
    } else {
        [FPLogger record:@"SignupVC: Change avartar to nil image"];
        return;
    }
    
    self.avatarImageView.image = photo;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
