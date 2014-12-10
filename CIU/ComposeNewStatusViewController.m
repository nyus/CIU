//
//  ComposeNewStatusViewController.m
//  FastPost
//
//  Created by Huang, Sihang on 12/4/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "ComposeNewStatusViewController.h"
#import "ComposeStatusPhotoCollectionViewCell.h"
#import <Parse/Parse.h>
#import "StatusObject.h"
#import "UITextView+Utilities.h"
#import "SharedDataManager.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"
#import "ELCAssetTablePicker.h"
#import "Helper.h"
#import "NSString+Utilities.h"

#define CELL_IMAGEVIEW_SIZE_HEIGHT 204.0f
#define CELL_IMAGEVIEW_SIZE_WIDTH 204.0f

static CGFloat kOptionsViewOriginalBottomSpace = 0.0;

@interface ComposeNewStatusViewController ()<UITextViewDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIActionSheetDelegate,UICollectionViewDataSource,UICollectionViewDelegate,ELCImagePickerControllerDelegate>{
    UIImagePickerController *imagePicker;
    UILabel *placeHolderLabel;
    NSMutableArray *collectionViewDataSource;
    NSArray *pickerDataSource;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *optionsViewBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomSpaceToOptionsViewConstraint;
@property (strong, nonatomic) UIActionSheet *photosActionSheet;
@end

@implementation ComposeNewStatusViewController

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
    [self configureTextView];
    
    if (!IS_4_INCH_SCREEN) {
        int delta = self.textViewHeightConstraint.constant - 140;
        self.textViewHeightConstraint.constant = 140;
        self.collectionViewTopSpacingConstraint.constant = self.collectionViewTopSpacingConstraint.constant - delta;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kOptionsViewOriginalBottomSpace = self.optionsViewBottomSpaceConstraint.constant;
    });
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.textView layoutIfNeeded];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
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
    
//    if (IS_4_INCH_SCREEN) {
//        self.textViewHeightConstraint.constant = 180;
//    } else if (IS_4_7_INCH_SCREEN) {
//        self.textViewHeightConstraint.constant = 111;
//    } else if (IS_5_5_INCH_SCREEN) {
//        self.textViewHeightConstraint.constant = 111;
//    } else {
//        self.textViewHeightConstraint.constant = 46;
//    }
//
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
    
    //send to parse
    [self dismissViewControllerAnimated:YES completion:^{
        
        dispatch_queue_t queue = dispatch_queue_create("save to parse and local", NULL);
        dispatch_async(queue, ^{
            
            //save to server
            PFObject *newStatus = [PFObject objectWithClassName:@"Status"];
            newStatus[@"message"] = self.textView.text;
            newStatus[@"posterUsername"] = [[PFUser currentUser] username];
            newStatus[@"posterFirstName"] = [[PFUser currentUser] objectForKey:@"firstName"];
            newStatus[@"posterLastName"] = [[PFUser currentUser] objectForKey:@"lastName"];
            newStatus[@"commentCount"]=@0;
            newStatus[@"photoCount"] = [NSNumber numberWithInt:(int)collectionViewDataSource.count];
            newStatus[@"anonymous"] = [NSNumber numberWithBool:self.anonymousSwitch.on];
            newStatus[@"isBadContent"] = @NO;
            NSDictionary *dictionary = [Helper userLocation];
            if (dictionary) {
                newStatus[@"latitude"] = dictionary[@"latitude"];
                newStatus[@"longitude"] = dictionary[@"longitude"];
            }
            
            NSString *photoID;
            if (collectionViewDataSource.count!=0) {
                photoID =[NSString generateUniqueId];
                newStatus[@"photoID"] = photoID;
            }
            //save to parse and local
            [newStatus saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    
                    //picture
                    for(UIImage *image in collectionViewDataSource){
                        
                        UIImage *scaled = [Helper scaleImage:image downToSize:CGSizeMake(CELL_IMAGEVIEW_SIZE_WIDTH, CELL_IMAGEVIEW_SIZE_HEIGHT)];
                        PFFile *photo = [PFFile fileWithData:UIImagePNGRepresentation(scaled)];
                        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (succeeded) {
                                PFObject *object = [[PFObject alloc] initWithClassName:@"Photo"];
                                [object setObject:photoID forKey:@"photoID"];
                                [object setObject:photo forKey:@"image"];
                                [object setObject:@NO forKey:@"isHighRes"];
                                [object setObject:[PFUser currentUser].username forKey:@"username"];
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
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            // this is for a bug when you first add from gallery, then take a photo, the picker view controller shifts down
            //            if (imagePicker == nil) {
            imagePicker = [[UIImagePickerController alloc] init];
            //            }
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.allowsEditing = YES;
            imagePicker.cameraCaptureMode = (UIImagePickerControllerCameraCaptureModePhoto);
            imagePicker.delegate = self;
            [self presentViewController:imagePicker animated:YES completion:nil];
        }
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

    if(!collectionViewDataSource){
        collectionViewDataSource = [NSMutableArray array];
    }
    for (NSDictionary *dict in info) {
        UIImage *image = dict[@"UIImagePickerControllerOriginalImage"];
        image = [Helper scaleImage:image downToSize:CGSizeMake(CELL_IMAGEVIEW_SIZE_WIDTH, CELL_IMAGEVIEW_SIZE_HEIGHT)];
        [collectionViewDataSource addObject:image];
    }
    
    [self.collectionView reloadData];
    [self dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:.2 animations:^{
            [self changeTextViewHeightToFitPhoto];
            [self showCollectionViewAndLineSeparator];
        }];
        
        [self.textView becomeFirstResponder];
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
    
    image = [Helper scaleImage:image downToSize:CGSizeMake(CELL_IMAGEVIEW_SIZE_WIDTH, CELL_IMAGEVIEW_SIZE_HEIGHT)];
    
    
    if (!collectionViewDataSource) {
        collectionViewDataSource = [NSMutableArray array];
    }
    [collectionViewDataSource addObject:image];
    
    [self.collectionView reloadData];
    
    [picker dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:.2 animations:^{
            [self changeTextViewHeightToFitPhoto];
            [self showCollectionViewAndLineSeparator];
        }];
        
        [self.textView becomeFirstResponder];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.textView becomeFirstResponder];
    }];
}

#pragma mark - UICollectionViewDelegate

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return collectionViewDataSource.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ComposeStatusPhotoCollectionViewCell *cell = (ComposeStatusPhotoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.imageView.image = [collectionViewDataSource objectAtIndex:indexPath.row];
    return cell;
}
@end
