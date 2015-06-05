//
//  CommentStatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CommentVC.h"
#import <Parse/Parse.h>
#import "AvatarAndUsernameTableViewCell.h"
#import "Helper.h"
#import "LoadingTableViewCell.h"
#import "UITextView+Utilities.h"
#import "Helper.h"
#import "SurpriseTableViewCell.h"

static CGFloat const kCommentLabelWidth = 245.0;
static CGFloat const kNoCommentCellHeight = 250.0;
static CGFloat const kCellImageViewMaxY = 45;
static CGFloat const kCommentLabelOriginY = 19.0;

static UIImage *defaultAvatar;

@interface CommentVC () <UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,UIScrollViewDelegate>{
    //cache cell height
    NSMutableDictionary *cellHeightMap;
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

@implementation CommentVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        cellHeightMap = [NSMutableDictionary dictionary];
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
    
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *user, NSError *error) {
        //update status
        PFQuery *query = [[PFQuery alloc] initWithClassName:DDStatusParseClassName];
        [query whereKey:DDObjectIdKey equalTo:self.statusObjectId];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                // Send push notification
                PFQuery *userQuery = [PFUser query];
                [userQuery whereKey:DDUserNameKey equalTo:object[DDPosterUserNameKey]];
                
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:DDUserKey matchesQuery:userQuery];
                
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery];
                [push setMessage:[NSString stringWithFormat:@"%@ %@ commented on your surprise", [PFUser currentUser][DDFirstNameKey], [PFUser currentUser][DDLastNameKey]]];
                [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
                }];
                
                //increase comment count on Status object
                object[DDCommentCountKey] = [NSNumber numberWithInt:[object[DDCommentCountKey] intValue] +1];
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
        PFObject *object = [[PFObject alloc] initWithClassName:DDCommentParseClassName];
        object[DDSenderUserNameKey]= [PFUser currentUser].username;
        object[DDFirstNameKey] = [[PFUser currentUser] objectForKey:DDFirstNameKey];
        object[DDLastNameKey] = [[PFUser currentUser] objectForKey:DDLastNameKey];
        object[DDContentStringKey] = self.textView.text;
        object[DDStatusIdKey] = self.statusObjectId;
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
    }];
}

#pragma mark - keyboard notification 

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.enterMessageContainerViewBottomSpaceConstraint.constant = rect.size.height;
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
        return kNoCommentCellHeight;
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
        cell.commentStringLabel.text = comment[DDContentStringKey];
        if ([comment[DDAnonymousKey] boolValue]) {
            cell.usernameLabel.text = @"Anonymous";
        } else {
            cell.usernameLabel.text = [NSString stringWithFormat:@"%@ %@",comment[DDFirstNameKey],comment[DDLastNameKey]];
        }
        // Only load cached images; defer new downloads until scrolling ends. if there is no local cache, we download avatar in scrollview delegate methods
        if (!defaultAvatar) {
            defaultAvatar = [UIImage imageNamed:@"default-user-icon-profile.png"];
        }
        cell.avatarImageView.image = defaultAvatar;
        [self getAvatarForCell:cell withUsername:comment[DDSenderUserNameKey] loadIfStill:YES];

        return cell;
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadRemoteDataForVisibleCells];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self loadRemoteDataForVisibleCells];
    }
}

- (void)getAvatarForCell:(AvatarAndUsernameTableViewCell *)cell withUsername:(NSString *)username loadIfStill:(BOOL)loadIfStill
{
    UIImage *image = [Helper getLocalAvatarForUser:username isHighRes:NO];
    if (image) {
        cell.avatarImageView.image = image;
    }else{
        if (loadIfStill && self.tableView.isDecelerating == NO && self.tableView.isDragging == NO) {
            return;
        }
        
        [Helper getServerAvatarForUser:username
                             isHighRes:NO
                            completion:^(NSError *error, UIImage *image) {
                                cell.avatarImageView.image = image;
                            }];
    }
}

- (void)loadRemoteDataForVisibleCells
{
    for (AvatarAndUsernameTableViewCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[AvatarAndUsernameTableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            PFObject *comment = self.dataSource[indexPath.row];
            [self getAvatarForCell:cell withUsername:comment[DDSenderUserNameKey] loadIfStill:NO];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return kNoCommentCellHeight;
    }else{
        
        PFObject *comment = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)comment.hash];
        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
            
            return [[cellHeightMap objectForKey:key] floatValue];
        }else{
            NSString *contentString = comment[DDContentStringKey];
            CGRect boundingRect =[contentString boundingRectWithSize:CGSizeMake(kCommentLabelWidth, MAXFLOAT)
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]}
                                                             context:nil];
            if (kCommentLabelOriginY + boundingRect.size.height < kCellImageViewMaxY) {
                [cellHeightMap setObject:[NSNumber numberWithInt:kCellImageViewMaxY] forKey:key];
                
                return kCellImageViewMaxY;
            }else{
                [cellHeightMap setObject:@(kCommentLabelOriginY + boundingRect.size.height + 10) forKey:key];
                
                return kCommentLabelOriginY + boundingRect.size.height + 10;
            }
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
