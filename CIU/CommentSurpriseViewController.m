//
//  CommentStatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CommentSurpriseViewController.h"
#import <Parse/Parse.h>
#import "AvatarAndUsernameTableViewCell.h"
#import "Helper.h"
#import "LoadingTableViewCell.h"
#import "UITextView+Utilities.h"
#import "Helper.h"
#import "SurpriseTableViewCell.h"

#define COMMENT_LABEL_WIDTH 234.0f
#define NO_COMMENT_CELL_HEIGHT 250.0f
#define CELL_IMAGEVIEW_MAX_Y 35+10

static UIImage *defaultAvatar;
typedef NS_ENUM(NSUInteger, Direction){
    DirectionUp,
    DirectionDown,
    DirectionRight,
    DirectionLeft
};

@interface CommentSurpriseViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,UIScrollViewDelegate>{
    //cache cell height
    NSMutableDictionary *cellHeightMap;
    UISwipeGestureRecognizer *leftSwipeGesture;
    UISwipeGestureRecognizer *rightSwipeGesture;
    BOOL isLoading;
    BOOL isAnimating;
}
@property (strong, nonatomic) NSMutableArray *dataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMessageContainerViewBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, copy) void(^completion)();
@end

@implementation CommentSurpriseViewController

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
    [[GAnalyticsManager shareManager] trackScreen:@"Comment Surprise View"];
    isLoading = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"View comment suprise" timed:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"View comment suprise" withParameters:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    defaultAvatar = nil;
}

- (void)updateCommentCountWithBlock:(void (^)())completion{
    self.completion = completion;
}

-(void)setStatusObjectId:(NSString *)statusObjectId{
    _statusObjectId = statusObjectId;
    
    if (statusObjectId==nil) {
        return;
    }
    
    //fetch all the comments
    isLoading = YES;
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Comment"];
    [query whereKey:@"statusId" equalTo:statusObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        isLoading = NO;
        if (!error && objects) {
            if (!self.dataSource) {
                self.dataSource = [NSMutableArray array];
            }
            [self.dataSource addObjectsFromArray:objects];
            [self.tableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)clearCommentTableView{
    self.dataSource = nil;
    [self.tableView reloadData];
}

- (IBAction)sendComment:(id)sender {
    
    if (self.textView.text == nil || [self.textView.text isEqualToString:@""]) {
        return;
    }
    
    //update status
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Status"];
    [query whereKey:@"objectId" equalTo:self.statusObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            // Send push notification
            PFQuery *device = [PFInstallation query];
            if ([PFUser currentUser].username) {
                [device whereKey:DDUserNameKey equalTo:[PFUser currentUser].username];
            }else if([PFUser currentUser]){
                [device whereKey:DDUserKey equalTo:[PFUser currentUser]];
            }
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:device];
            [push setMessage:[NSString stringWithFormat:@"%@ %@ commented on your surprise", object[DDPosterFirstNameKey], object[DDPosterLastNameKey]]];
            [push sendPushInBackground];
            
            //increase comment count on Status object
            object[@"commentCount"] = [NSNumber numberWithInt:[object[@"commentCount"] intValue] +1];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [object saveEventually];
                    
                    if (self.completion) {
                        // Callback on SurpriseTableViewController that we have increamented the commetn count
                        self.completion();
                    }
                }
            }];
        }
    }];
    
    //create a new Comment object
    PFObject *object = [[PFObject alloc] initWithClassName:@"Comment"];
    object[@"senderUsername"]= [PFUser currentUser].username;
    object[@"firstName"] = [[PFUser currentUser] objectForKey:@"firstName"];
    object[@"lastName"] = [[PFUser currentUser] objectForKey:@"lastName"];
    object[@"contentString"] = self.textView.text;
    object[@"statusId"] = self.statusObjectId;
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [object saveEventually];
        }
    }];
    
    //notify SurpriseTableViewController to update the coment count on the cell
    self.completion();
    
    [self.tableView beginUpdates];

    //delete "No one has said anything yet" cell
    if ((!self.dataSource || self.dataSource.count==0) && [self.tableView numberOfRowsInSection:0]!=0) {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.dataSource addObject:object];
    //insert into table view
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(int)self.dataSource.count-1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    //clear out
    self.textView.text = nil;
    
    //increament comment count on the status tb cell
    self.statusTBCell.commentCountLabel.text = [NSString stringWithFormat:@"%d",self.statusTBCell.commentCountLabel.text.intValue+1];
}

#pragma mark - keyboard notification 

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat tabbarHeight = CGRectGetHeight(self.tabBarController.tabBar.frame);
    self.enterMessageContainerViewBottomSpaceConstraint.constant = rect.size.height - tabbarHeight;
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)handleKeyboardWillHide:(NSNotification *)notification{
    self.enterMessageContainerViewBottomSpaceConstraint.constant = 0;
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UITableViewDelete

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.dataSource == nil || self.dataSource.count == 0) {
        return 1;
    }else{
        return self.dataSource.count;
    }
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.dataSource == nil || self.dataSource.count == 0) {
        return NO_COMMENT_CELL_HEIGHT;
    }else{
        return 100;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.dataSource == nil || self.dataSource.count == 0) {

        if (isLoading) {
            LoadingTableViewCell *cell = (LoadingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"loadingCell" forIndexPath:indexPath];
            [cell.activityIndicator startAnimating];
            return cell;
        }else{
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noCommentCell" forIndexPath:indexPath];
            return cell;
        }
        
    }else{
        AvatarAndUsernameTableViewCell *cell = (AvatarAndUsernameTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        PFObject *comment = self.dataSource[indexPath.row];
        cell.commentStringLabel.text = comment[@"contentString"];
        cell.usernameLabel.text = [NSString stringWithFormat:@"%@ %@",comment[@"firstName"],comment[@"lastName"]];
        // Only load cached images; defer new downloads until scrolling ends. if there is no local cache, we download avatar in scrollview delegate methods
        if (!defaultAvatar) {
            defaultAvatar = [UIImage imageNamed:@"default-user-icon-profile.png"];
        }
        cell.avatarImageView.image = defaultAvatar;
        UIImage *image = [Helper getLocalAvatarForUser:comment[@"senderUsername"] isHighRes:NO];
        if (image) {
            cell.avatarImageView.image = image;
        }else{
            if (tableView.isDecelerating == NO && tableView.isDragging == NO && cell.avatarImageView.image == nil) {
                [Helper getServerAvatarForUser:comment[@"senderUsername"] isHighRes:NO completion:^(NSError *error, UIImage *image) {
                    cell.avatarImageView.image = image;
                }];
            }
        }
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return NO_COMMENT_CELL_HEIGHT;
    }else{
        
        PFObject *comment = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)comment.hash];
        //        NSLog(@"indexPath:%@",indexPath);
        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
            //            NSLog(@"return stored cell height: %f",[[cellHeightMap objectForKey:key] floatValue]);
            return [[cellHeightMap objectForKey:key] floatValue];
            
        }else{
            NSString *contentString = comment[@"contentString"];
            CGRect boundingRect =[contentString boundingRectWithSize:CGSizeMake(COMMENT_LABEL_WIDTH, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil];
            if (boundingRect.size.height < CELL_IMAGEVIEW_MAX_Y) {
                [cellHeightMap setObject:[NSNumber numberWithInt:CELL_IMAGEVIEW_MAX_Y] forKey:key];
                return CELL_IMAGEVIEW_MAX_Y;
            }else{
                [cellHeightMap setObject:@(boundingRect.size.height+10) forKey:key];
                return boundingRect.size.height+10;
            }
            
        }
    }
}

#pragma mark - UIScrollViewDelegate

//-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
//    if (!isAnimating && scrollView.contentOffset.y<0) {
//        isAnimating = YES;
//        //dismiss view
//        [self animateToDismissSelfWithDirection:DirectionDown];
//    }
//
//    if (!isAnimating && ((scrollView.contentSize.height<scrollView.frame.size.height && scrollView.contentOffset.y>0) ||
//        (scrollView.contentSize.height>=scrollView.frame.size.height && scrollView.contentOffset.y>scrollView.contentSize.height-scrollView.frame.size.height))) {
//        isAnimating = YES;
//        [self animateToDismissSelfWithDirection:DirectionUp];
//    }
//}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
//    [self loadImagesForOnscreenRows];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate)
	{
//        [self loadImagesForOnscreenRows];
    }
}

- (void)loadImagesForOnscreenRows
{
    if(self.dataSource == nil || self.dataSource.count == 0){
        return;
    }
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    
    for (NSIndexPath *indexPath in visiblePaths)
    {
        __block AvatarAndUsernameTableViewCell *cell = (AvatarAndUsernameTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        PFObject *comment = self.dataSource[indexPath.row];
        BOOL avatar = [Helper isLocalAvatarExistForUser:comment[@"senderUsername"]  isHighRes:NO];
        if (!avatar) {
            [Helper getServerAvatarForUser:comment[@"senderUsername"] isHighRes:NO completion:^(NSError *error, UIImage *image) {
                cell.avatarImageView.image = image;
            }];
        }
    }
}

-(void)scrollTextViewToShowCursor{
    [self.textView scrollTextViewToShowCursor];
}

#pragma mark - uitextview delegate

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:nil afterDelay:0.1f];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:NSStringFromRange(range) afterDelay:0.1f];
    return YES;
}

@end
