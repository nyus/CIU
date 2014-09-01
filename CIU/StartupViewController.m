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
    
    PFUser *user = [PFUser currentUser];
    if (user || [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        [self reloadTableView];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleDismissLogin{
    [self reloadTableView];
}

-(void)reloadTableView{
    self.dataSource = [NSArray arrayWithObjects:@"userProfile",@"About CIU",@"Rate CIU",@"Feedback",@"Share CIU", nil];
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
    else{
    
    }
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
