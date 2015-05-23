//
//  ComposeNewStatusViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 12/4/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "ComposeSurpriseVC.h"
#import "ComposeSurprisePhotoCollectionViewCell.h"
#import <Parse/Parse.h>
#import "StatusObject.h"
#import "UITextView+Utilities.h"
#import "SharedDataManager.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"
#import "Helper.h"
#import "NSString+Utilities.h"
#import "SurpriseTableViewCell.h"
#import "NSString+Utilities.h"

static CGFloat kOptionsViewOriginalBottomSpace = 0.0;

@interface ComposeSurpriseVC ()<UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate,UICollectionViewDataSource,UICollectionViewDelegate,ELCImagePickerControllerDelegate>{
    UIImagePickerController *imagePicker;
    UILabel *placeHolderLabel;
    NSMutableArray *collectionViewDataSource;
    NSArray *pickerDataSource;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsViewBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomSpaceToOptionsViewConstraint;
@property (strong, nonatomic) UIActionSheet *photosActionSheet;
@end

@implementation ComposeSurpriseVC

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
    
    [[GAnalyticsManager shareManager] trackScreen:@"Compose Surprise"];
    
    [self configureTextView];
        
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kOptionsViewOriginalBottomSpace = self.optionsViewBottomSpaceConstraint.constant;
    });
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"View compose surprise" timed:YES];
    [self.textView layoutIfNeeded];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"View compose surprise" withParameters:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - keyboard notification

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.optionsViewBottomSpaceConstraint.constant = rect.size.height;
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)handleKeyboardWillHide:(NSNotification *)notification{
    
    self.optionsViewBottomSpaceConstraint.constant = kOptionsViewOriginalBottomSpace;
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)configureTextView{
    [self.textView becomeFirstResponder];
    if (self.textView.hasText) {
        [self hidePlaceHolderText];
    }else{
        [self showPlaceHolderText];
    }
}

-(void)showPlaceHolderText{
    if (!placeHolderLabel) {
        placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 12, 200, 20)];
        placeHolderLabel.backgroundColor = [UIColor clearColor];
        placeHolderLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:18];
        placeHolderLabel.textColor = [UIColor grayColor];
        placeHolderLabel.text = @"What's on your mind?";
        [self.textView addSubview:placeHolderLabel];
    }
    placeHolderLabel.hidden = NO;
}

-(void)hidePlaceHolderText{
    placeHolderLabel.hidden = YES;
}

-(void)changeTextViewHeightToFitPhoto{
    
    self.textViewBottomSpaceToOptionsViewConstraint.constant = self.collectionView.frame.size.height;
    [self.view layoutIfNeeded];
    [self scrollTextViewToShowCursor];
}

-(void)showCollectionViewAndLineSeparator{
    self.textPhotoSeparatorView.alpha = 1.0f;
    self.collectionView.alpha = 1.0f;
}

- (void)scrollTextViewToShowCursor {
    [self.textView scrollTextViewToShowCursor];
}

#pragma mark - UITextViewDelegate

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:nil afterDelay:0.1f];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if (textView.text.length == 1 && [text isEqualToString:@""]) {
        [self showPlaceHolderText];
    }else{
        [self hidePlaceHolderText];
    }
    
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:NSStringFromRange(range) afterDelay:0.1f];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange{
    return YES;
}

#pragma mark - IBAction

- (IBAction)attachPhotoButtonTapped:(id)sender {
    
    [self.textView resignFirstResponder];
    self.photosActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Add From Gallery", nil];
    [self.photosActionSheet showInView:self.view];
}

- (IBAction)sendButtonTapped:(id)sender {

    if ([[self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        return;
    }
    
    BOOL isAdmin = [[PFUser currentUser][DDIsAdminKey] boolValue];
    if (!isAdmin && [self.textView.text containsURL]) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"External links are not allowed.", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Got it", nil)
                          otherButtonTitles:nil, nil] show];
        
        return;
    }
    
    //send to parse
    [self dismissViewControllerAnimated:YES completion:^{
        
        dispatch_queue_t queue = dispatch_queue_create("save to parse and local", NULL);
        dispatch_async(queue, ^{
            
            //save to server
            PFObject *newStatus = [PFObject objectWithClassName:DDStatusParseClassName];
            newStatus[DDMessageKey] = self.textView.text;
            newStatus[DDPosterUserNameKey] = [[PFUser currentUser] username];
            newStatus[DDPosterFirstNameKey] = [[PFUser currentUser] objectForKey:DDFirstNameKey];
            newStatus[DDPosterLastNameKey] = [[PFUser currentUser] objectForKey:DDLastNameKey];
            newStatus[DDCommentCountKey] = @0;
            newStatus[DDPhotoCountKey] = [NSNumber numberWithInt:(int)collectionViewDataSource.count];
            newStatus[DDAnonymousKey] = [NSNumber numberWithBool:self.anonymousSwitch.on];
            newStatus[DDIsBadContentKey] = @NO;
            if ([[PFUser currentUser] objectForKey:DDIsAdminKey]) {
                newStatus[DDIsStickyPostKey] = [[PFUser currentUser] objectForKey:DDIsAdminKey];
            } else {
                newStatus[DDIsStickyPostKey] = @NO;
            }
            
            NSDictionary *dictionary = [Helper userLocation];
            if (dictionary) {
                newStatus[DDLatitudeKey] = dictionary[DDLatitudeKey];
                newStatus[DDLongitudeKey] = dictionary[DDLongitudeKey];
                [[GAnalyticsManager shareManager] trackUIAction:@"compose new surprise"
                                                          label:[NSString stringWithFormat:@"location:%f %f",
                                                                 [dictionary[DDLatitudeKey] floatValue],
                                                                 [dictionary[DDLongitudeKey] floatValue]]
                                                          value:nil];
                [Flurry logEvent:@"Compose new surprise" withParameters:@{DDLatitudeKey:@([dictionary[DDLatitudeKey] floatValue]),
                                                                          DDLongitudeKey:@([dictionary[DDLongitudeKey] floatValue])}];
            }
            
            NSString *photoID;
            if (collectionViewDataSource.count!=0) {
                photoID =[NSString generateUniqueId];
                newStatus[DDPhotoIdKey] = photoID;
            }
            //save to parse and local
            [newStatus saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    
                    //picture
                    for(UIImage *image in collectionViewDataSource){
                        
                        UIImage *scaled = [Helper scaleImage:image downToSize:CGSizeMake([SurpriseTableViewCell imageViewWidth], [SurpriseTableViewCell imageViewHeight])];
                        PFFile *photo = [PFFile fileWithData:UIImagePNGRepresentation(scaled)];
                        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                PFObject *object = [[PFObject alloc] initWithClassName:DDPhotoParseClassName];
                                object[DDPhotoIdKey] = photoID;
                                object[DDImageKey] = photo;
                                object[DDIsHighResKey] = @NO;
                                object[DDUserNameKey] = [PFUser currentUser].username;
                                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    if (!succeeded) {
                                        [object saveEventually];
                                    }
                                }];
                            }
                        }];
                    }
                }else{
                    [newStatus saveEventually];
                }
            }];
        });
    }];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)anonymousSwitchChanged:(id)sender {
    
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    // Dismiss the actionSheet before launching the camera, so that it doesn't jump into portrait for a split second
    [self.photosActionSheet dismissWithClickedButtonIndex:999 animated:YES];
    
    if(buttonIndex == 0){
        [Helper launchCameraInController:self];
    }else if(buttonIndex == 1){

        ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initImagePicker];
        elcPicker.maximumImagesCount = 30;
        elcPicker.returnsOriginalImage = NO; //Only return the fullScreenImage, not the fullResolutionImage
        elcPicker.imagePickerDelegate = self;

        [self presentViewController:elcPicker animated:YES completion:nil];
    }else{
        [self.textView becomeFirstResponder];
    }
}

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in info) {
        [array addObject:dict[@"UIImagePickerControllerOriginalImage"]];
    }
    
    [self displayAndStorePickedImages:array];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self adjustUIAfterDismissImagePicker];
    }];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - image picker delegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if (!image) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[info objectForKey:UIImagePickerControllerReferenceURL] absoluteString]]];
        image = [UIImage imageWithData:data];
    }
    
    [self displayAndStorePickedImages:@[image]];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [self adjustUIAfterDismissImagePicker];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.textView becomeFirstResponder];
    }];
}

- (void)adjustUIAfterDismissImagePicker
{
    [UIView animateWithDuration:.2 animations:^{
        [self changeTextViewHeightToFitPhoto];
        [self showCollectionViewAndLineSeparator];
    }];
    
    [self.textView becomeFirstResponder];
}

#pragma mark - Helper

- (void)displayAndStorePickedImages:(NSArray *)images
{
    if(!collectionViewDataSource){
        collectionViewDataSource = [NSMutableArray array];
    }
    for (UIImage *image in images) {
        UIImage *scaledImage = [Helper scaleImage:image downToSize:CGSizeMake([SurpriseTableViewCell imageViewWidth], [SurpriseTableViewCell imageViewHeight])];
        [collectionViewDataSource addObject:scaledImage];
    }
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return collectionViewDataSource.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ComposeSurprisePhotoCollectionViewCell *cell = (ComposeSurprisePhotoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageView.image = [collectionViewDataSource objectAtIndex:indexPath.row];
    return cell;
}
@end
