//
//  StartupViewController.m
//  CIU
//
//  Created by Huang, Jason on 8/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "StartupViewController.h"
#import "AvatarAndUsernameTableViewCell.h"
#import "Helper.h"
#import <Parse/Parse.h>
#import <MessageUI/MFMailComposeViewController.h>

NS_ENUM(NSUInteger, SideBarStatus){
    SideBarStatusClosed=0,
    SideBarStatusOpen=1
};
#define SIDE_BAR_OPEN_DISTANCE 150.0f
#define SIDE_BAR_CLOSE_DISTANCE 0.0f
#define AVATAR_CELL_HEIGHT 102.0f
#define OTHER_CELL_HEIGHT 44.0f
@interface StartupViewController()<UITableViewDataSource,UITableViewDelegate,MFMailComposeViewControllerDelegate>{
    CGPoint previousPoint;
}
@property (nonatomic, strong) NSArray *dataSource;
@end

@implementation StartupViewController

-(void)viewDidLoad{
    
    PFUser *user = [PFUser currentUser];
    if (user || [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self reloadTableView];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSideBarSlideOpen) name:@"sideBarSlideOpen" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDismissLogin) name:@"dismissLogin" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDownloadFacebookProfilePicComplete) name:@"downloadFacebookProfilePicComplete" object:nil];
    PFUser *user = [PFUser currentUser];
    if (user || [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self reloadTableView];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleDownloadFacebookProfilePicComplete{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)handleDismissLogin{
    [self reloadTableView];
}

-(void)reloadTableView{
    self.dataSource = [NSArray arrayWithObjects:@"userProfile",@"About CIU",@"Rate CIU",@"Feedback",@"Share CIU",@"Log out", nil];
    [self.tableView reloadData];
}

- (IBAction)handlePanContainerView:(UIPanGestureRecognizer *)sender {
   CGPoint point = [sender translationInView:self.view];
    float deltaX = point.x - previousPoint.x;
    previousPoint = point;
    if (self.containerViewLeadingSpaceConstraint.constant + deltaX <0 || self.containerViewLeadingSpaceConstraint.constant + deltaX >SIDE_BAR_OPEN_DISTANCE) {
        return;
    }
    self.containerViewLeadingSpaceConstraint.constant += deltaX;
    
    //reset
    if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateFailed) {
        previousPoint = CGPointZero;
        [self animateSideBarToOpenOrClose];
    }
}

-(void)animateSideBarToOpenOrClose{
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if (self.containerViewLeadingSpaceConstraint.constant < SIDE_BAR_OPEN_DISTANCE/2) {
        
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_CLOSE_DISTANCE;
    }else{
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_OPEN_DISTANCE;
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
    
    if (self.containerViewLeadingSpaceConstraint.constant==0) {
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_OPEN_DISTANCE;
    }else{
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_CLOSE_DISTANCE;
    }
    
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
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
        [Helper getAvatarForUser:[PFUser currentUser].username isHighRes:NO completion:^(NSError *error, UIImage *image) {
            if (!error) {
                c.avatarImageView.image = image;
            }
        }];
        c.usernameLabel.text = [NSString stringWithFormat:@"%@ %@",[[PFUser currentUser] objectForKey:@"firstName"],[[PFUser currentUser] objectForKey:@"lastName"]];
    }else{
        
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        cell.textLabel.text = self.dataSource[indexPath.row];
        
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
    //log out
    else {
        [PFUser logOut];
        UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
        [self presentViewController:vc animated:YES completion:nil];
    }
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
                                       @"CIU Mobile App", @"name",
                                       @"Let CIU make your life easier today!", @"caption",
                                       @"CIU is the best Chinese lifestyle app from restaurants to supermarkets, frome job hunting to online trading.", @"description",
                                       @"https://developers.facebook.com/docs/ios/share/", @"link",
                                       @"http://i.imgur.com/g3Qc1HN.png", @"picture",
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

// A function for parsing URL parameters returned by the Feed Dialog.
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
@end
