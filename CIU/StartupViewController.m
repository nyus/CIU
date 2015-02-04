//
//  StartupViewController.m
//  CIU
//
//  Created by Huang, Sihang on 8/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "StartupViewController.h"
#import "AvatarAndUsernameTableViewCell.h"
#import "Helper.h"
#import <Parse/Parse.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "UIColor+CIUColors.h"

NS_ENUM(NSUInteger, SideBarStatus){
    SideBarStatusClosed=0,
    SideBarStatusOpen=1
};

#define SIDE_BAR_OPEN_DISTANCE -150.0f
#define SIDE_BAR_CLOSE_DISTANCE 0.0f
#define AVATAR_CELL_HEIGHT 102.0f
#define OTHER_CELL_HEIGHT 44.0f

static CGFloat leadingSpace;


@interface StartupViewController()<UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate, AvatarAndUsernameTableViewCellDelegate>{
    CGPoint previousPoint;
}

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (weak, nonatomic) IBOutlet UIView *container;
@property (strong, nonatomic) UIImageView *blurView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewLeadingSpaceConstraint;

@end

@implementation StartupViewController

-(void)viewDidLoad{
    [self reloadTableView];
    
    //set UI of menu tableview
    self.tableView.backgroundColor = [UIColor themeGreen];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.view.backgroundColor = [UIColor themeGreen];
    
    //this is just a hot fix. need to think about the flow.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSideBarSlideOpen) name:@"sideBarSlideOpen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDismissLogin) name:@"dismissLogin" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadFacebookProfilePicComplete) name:@"downloadFacebookProfilePicComplete" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)handleDownloadFacebookProfilePicComplete{
    NSInteger numOfRows = [self.tableView numberOfRowsInSection:0];
    if (numOfRows > 0) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    }
}

-(void)handleDismissLogin{
    [self reloadTableView];
}

-(void)reloadTableView{
    self.dataSource = [NSArray arrayWithObjects:@"userProfile",@"About",@"Rate",@"Feedback",@"Share",@"Terms of Use",@"Log out", nil];
    [self.tableView reloadData];
}

- (void)recordInitialAutoLayout
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        leadingSpace = self.containerViewLeadingSpaceConstraint.constant;
    });
}

- (IBAction)handlePanContainerView:(UIPanGestureRecognizer *)sender {
    
    [self recordInitialAutoLayout];
    
   CGPoint point = [sender translationInView:self.view];
    float deltaX = point.x - previousPoint.x;
    previousPoint = point;
    if (self.containerViewLeadingSpaceConstraint.constant - deltaX > leadingSpace || self.containerViewLeadingSpaceConstraint.constant - deltaX < leadingSpace + SIDE_BAR_OPEN_DISTANCE) {
        return;
    }
    self.containerViewLeadingSpaceConstraint.constant -= deltaX;
    
    //reset
    if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateFailed) {
        previousPoint = CGPointZero;
        [self animateSideBarToOpenOrClose];
    }
}

-(void)animateSideBarToOpenOrClose{
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self recordInitialAutoLayout];
    
    if (self.containerViewLeadingSpaceConstraint.constant > (leadingSpace + SIDE_BAR_OPEN_DISTANCE)/2) {
        
        self.containerViewLeadingSpaceConstraint.constant = leadingSpace;
        
        //remove blur effect
        [self setBlurEffect:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarOpen" object:nil userInfo:@{@"open":@NO}];
        
    }else{
        self.containerViewLeadingSpaceConstraint.constant = leadingSpace + SIDE_BAR_OPEN_DISTANCE;
        
        //add blur effect
        [self setBlurEffect:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarOpen" object:nil userInfo:@{@"open":@YES}];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

-(void)handleSideBarSlideOpen{
    [self animateSideBarWhenMenuTapped];
}

-(void)animateSideBarWhenMenuTapped{
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    [self recordInitialAutoLayout];
    
    if (self.containerViewLeadingSpaceConstraint.constant == leadingSpace) {
        self.containerViewLeadingSpaceConstraint.constant = leadingSpace + SIDE_BAR_OPEN_DISTANCE;

        //add blur effect
        [self setBlurEffect:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarOpen" object:nil userInfo:@{@"open":@YES}];
    }else{
        self.containerViewLeadingSpaceConstraint.constant = leadingSpace;

        //remove blur effect
        [self setBlurEffect:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarOpen" object:nil userInfo:@{@"open":@NO}];
    }
    
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

#pragma mark - Blur effect
- (void)setBlurEffect:(BOOL)setBlurEffect
{
    if(!self.blurView){
        self.blurView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.container.frame.size.width, self.container.frame.size.height)];
        self.blurView.image = [UIImage imageNamed:@"mask"];
    }
    
    if(setBlurEffect){
        [self.container addSubview:self.blurView];
    }else{
        [self.blurView removeFromSuperview];
    }
    
}

#pragma mark - UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"avatarCell" forIndexPath:indexPath];
        __block AvatarAndUsernameTableViewCell *c = (AvatarAndUsernameTableViewCell *)cell;
        c.delegate = self;
        
        PFUser *user = [PFUser currentUser];
        if (user || [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            [Helper getAvatarForUser:[PFUser currentUser].username isHighRes:NO completion:^(NSError *error, UIImage *image) {
                if (!error) {
                    c.avatarImageView.image = image;
                    c.backgroundColor = [UIColor clearColor];
                }
            }];
            c.usernameLabel.text = [NSString stringWithFormat:@"%@ %@",[[PFUser currentUser] objectForKey:@"firstName"],[[PFUser currentUser] objectForKey:@"lastName"]];
            
        } else {
            c.usernameLabel.text = @"";
        }
        
        c.usernameLabel.font = [UIFont fontWithName:@"Helvetica" size:15.0];
        c.usernameLabel.textColor = [UIColor themeTextGrey];
        c.backgroundColor = [UIColor themeGreen];
        
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        cell.textLabel.text = self.dataSource[indexPath.row];
        cell.textLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15.0];
        cell.textLabel.textColor = [UIColor themeTextGrey];
        cell.textLabel.textAlignment = NSTextAlignmentRight;
        
        cell.backgroundColor = [UIColor themeGreen];
        
        //seperator
        CGSize textSize = [self.dataSource[indexPath.row] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica-Bold" size:15.0], NSFontAttributeName, nil]];
        
        UIView *seperator = [[UIView alloc] initWithFrame:CGRectMake(cell.frame.size.width - 30 - textSize.width, cell.frame.size.height - 5.0, textSize.width + 15, 1.0)];
        seperator.backgroundColor = [UIColor colorWithRed:36.0/255.0 green:36.0/255.0 blue:36.0/255.0 alpha:1.0f];
        [cell addSubview:seperator];
        
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //Profile
    if (indexPath.row == 0) {
        
    }
    //About CIU
    else if (indexPath.row == 1){
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"aboutus"];
        [self presentViewController:vc animated:YES completion:nil];
    }
    //Rate CIU
    else if (indexPath.row == 2){
        NSURL *url = [NSURL URLWithString:@"itms-apps://itunes.apple.com/app/appid"];
        [[UIApplication sharedApplication] openURL:url];
    }
    //Feedback
    else if(indexPath.row == 3){
        MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
        [vc setToRecipients:@[@"8miletech@gmail.com"]];
        vc.mailComposeDelegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }
    //share this app
    else if(indexPath.row == 4){
        [self shareToFacebook];
    }
    //Terms of Use
    else if (indexPath.row == 5){
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"termsAndPrivacy"];
        [self presentViewController:vc animated:YES completion:nil];
    }
    //log out
    else {
        [PFUser logOut];
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
        [self presentViewController:vc animated:YES completion:^{
            [self animateSideBarWhenMenuTapped];
        }];
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
}

-(void)shareToFacebook{
    // Check if the Facebook app is installed and we can present the share dialog
    FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
#warning this link should be replaced by app store link
    params.link = [NSURL URLWithString:@"http://www.8miletech.com"];
    
    // If the Facebook app is installed and we can present the share dialog
    if ([FBDialogs canPresentShareDialogWithParams:params]) {
        
        // Present share dialog
        [FBDialogs presentShareDialogWithLink:params.link
                                      handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                          if(error) {
                                              // An error occurred, we need to handle the error
                                              // See: https://developers.facebook.com/docs/ios/errors
                                              NSLog(@"Error publishing story: %@", error.description);
                                          } else {
                                              // Success
                                              NSLog(@"result %@", results);
                                          }
                                      }];
        
        // If the Facebook app is NOT installed and we can't present the share dialog
    } else {
        // FALLBACK: publish just a link using the Feed dialog
        
        // Put together the dialog parameters
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"DaDa 哒哒", @"name",
                                       @"Let DaDaC make your life easier today!", @"caption",
                                       @"No. 1 App for Chinese in USA！找房子，买车子，吃中餐？还是交朋友，拼车游，参加派对？Hurry up! 熊猫DaDa带你玩转美国！", @"description",
                                       @"https://developers.facebook.com/docs/ios/share/", @"link",
                                       @"http://www.8miletech.com/wp-content/uploads/2015/01/CIU-logo-225-12.7.png", @"picture",
                                       nil];
        
        // Show the feed dialog
        [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // An error occurred, we need to handle the error
                                                          // See: https://developers.facebook.com/docs/ios/errors
                                                          NSLog(@"Error publishing story: %@", error.description);
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // User canceled.
                                                              NSLog(@"User cancelled.");
                                                          } else {
                                                              // Handle the publish feed callback
                                                              NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                                                              
                                                              if (![urlParams valueForKey:@"post_id"]) {
                                                                  // User canceled.
                                                                  NSLog(@"User cancelled.");
                                                                  
                                                              } else {
                                                                  // User clicked the Share button
                                                                  NSString *result = [NSString stringWithFormat: @"Posted story, id: %@", [urlParams valueForKey:@"post_id"]];
                                                                  NSLog(@"result %@", result);
                                                              }
                                                          }
                                                      }
                                                  }];
    }

}

- (NSDictionary*)parseURLParams:(NSString *)query {
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    return params;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return AVATAR_CELL_HEIGHT;
    }else{
        return OTHER_CELL_HEIGHT;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return AVATAR_CELL_HEIGHT;
    }else{
        return OTHER_CELL_HEIGHT;
    }
}

#pragma mark - MFMail

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AvatarAndUsernameTableViewCellDelegate

- (void)avatarImageViewTappedWithCell:(AvatarAndUsernameTableViewCell *)cell{
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take A Photo",@"Add From Gallery", nil];
    [actionsheet showInView:self.view];
}

#pragma mark - Tap to switch image 

- (IBAction)imageViewTapped:(id)sender {
    
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

- (void) launchCameraPicker {
    [Helper launchCameraInController:self];
}

- (void) launchGalleryPicker {
    [Helper launchPhotoLibraryInController:self];
}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *photo = nil;
    if (info[@"UIImagePickerControllerEditedImage"]) {
        photo = info[@"UIImagePickerControllerEditedImage"];
    } else {
        photo = info[@"UIImagePickerControllerOriginalImage"];
    }
    
    //access cell
    AvatarAndUsernameTableViewCell *cell = (AvatarAndUsernameTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [Helper saveChosenPhoto:photo andSetOnImageView:cell.avatarImageView];
}
@end
