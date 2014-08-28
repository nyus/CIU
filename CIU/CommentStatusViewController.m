//
//  CommentStatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CommentStatusViewController.h"
#import <Parse/Parse.h>
#import "AvatarAndUsernameTableViewCell.h"
#import "Helper.h"
#import "LoadingTableViewCell.h"
#import "UITextView+Utilities.h"
#import "Helper.h"
#import "StatusTableViewCell.h"
#import "StatusViewController.h"
#define COMMENT_LABEL_WIDTH 234.0f
#define NO_COMMENT_CELL_HEIGHT 250.0f
#define CELL_IMAGEVIEW_MAX_Y 35+10
typedef NS_ENUM(NSUInteger, Direction){
    DirectionUp,
    DirectionDown,
    DirectionRight,
    DirectionLeft
};

@interface CommentStatusViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate,UIScrollViewDelegate>{
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
@end

@implementation CommentStatusViewController

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
    if (!leftSwipeGesture) {
        leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:leftSwipeGesture];
    }
    
    if (!rightSwipeGesture) {
        rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:rightSwipeGesture];
    }
    
    isLoading = YES;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [self.view removeGestureRecognizer:leftSwipeGesture];
    [self.view removeGestureRecognizer:rightSwipeGesture];
    leftSwipeGesture = nil;
    rightSwipeGesture = nil;
}

-(void)handleSwipe:(UISwipeGestureRecognizer *)swipe{
    if (swipe.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self animateToDismissSelfWithDirection:DirectionLeft];
    }else if (swipe.direction == UISwipeGestureRecognizerDirectionRight){
        [self animateToDismissSelfWithDirection:DirectionRight];
    }
}

-(void)animateToDismissSelfWithDirection:(Direction)direction{
    [self.textView resignFirstResponder];
    self.enterMessageContainerView.hidden = YES;
    
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        if (direction == DirectionUp) {
            self.view.frame = CGRectMake(0, -self.statusVC.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
        }else if (direction == DirectionDown){
            self.view.frame = CGRectMake(0, self.statusVC.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
        }else if(direction == DirectionLeft){
            self.view.frame = CGRectMake(-self.view.frame.size.width,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height);
        }else{
            self.view.frame = CGRectMake(self.view.frame.size.width,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height);
        }
        
        self.statusVC.shadowView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.enterMessageContainerView.hidden= NO;
        isAnimating = NO;
        self.statusVC.tableView.userInteractionEnabled = YES;
    }];
}

-(void)clearReference{
    self.statusTBCell = nil;
    self.statusObjectId = nil;
    self.animateEndFrame = CGRectNull;
    self.statusVC = nil;
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
            
            //increase comment count on Status object
            object[@"commentCount"] = [NSNumber numberWithInt:[object[@"commentCount"] intValue] +1];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!succeeded) {
                    [object saveEventually];
                }
            }];
        }
    }];
    
    //create a new Comment object
    PFObject *object = [[PFObject alloc] initWithClassName:@"Comment"];
    object[@"senderUsername"]= [PFUser currentUser].username;
    object[@"contentString"] = self.textView.text;
    object[@"statusId"] = self.statusObjectId;
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [object saveEventually];
        }
    }];
    
    [self.dataSource addObject:object];
    [self.tableView reloadData];
    
    //clear out
    self.textView.text = nil;
    
    //increament comment count on the status tb cell
    self.statusTBCell.commentCountLabel.text = [NSString stringWithFormat:@"%d",self.statusTBCell.commentCountLabel.text.intValue+1];
}

#pragma mark - keyboard notification 

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect convertedRect =  [self.view convertRect:rect fromView:nil];
    self.enterMessageContainerViewBottomSpaceConstraint.constant += self.view.frame.size.height - convertedRect.origin.y;
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
        
        // Only load cached images; defer new downloads until scrolling ends. if there is no local cache, we download avatar in scrollview delegate methods
        BOOL isLocalCache = NO;
#warning 
//        cell.avatarImageView.image = [UIImage imageNamed:@"default-user-icon-profile.png"];
//        UIImage *image = [Helper getLocalAvatarForUser:comment[@"senderUsername"] avatarType:AvatarTypeMid isHighRes:NO];
//        if (image) {
//            isLocalCache = YES;
//            cell.avatarImageView.image = image;
//        }else{
//            if (tableView.isDecelerating == NO && tableView.isDragging == NO && cell.avatarImageView.image == nil) {
//                [Helper getServerAvatarForUser:comment[@"senderUsername"] avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
//                    cell.avatarImageView.image = image;
//                }];
//            }
//        }
        
//        [Helper getAvatarForUser:comment[@"senderUsername"] avatarType:AvatarTypeMid forImageView:cell.avatarImageView];
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

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (!isAnimating && scrollView.contentOffset.y<0) {
        isAnimating = YES;
        //dismiss view
        [self animateToDismissSelfWithDirection:DirectionDown];
    }

    if (!isAnimating && ((scrollView.contentSize.height<scrollView.frame.size.height && scrollView.contentOffset.y>0) ||
        (scrollView.contentSize.height>=scrollView.frame.size.height && scrollView.contentOffset.y>scrollView.contentSize.height-scrollView.frame.size.height))) {
        isAnimating = YES;
        [self animateToDismissSelfWithDirection:DirectionUp];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadImagesForOnscreenRows];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

- (void)loadImagesForOnscreenRows
{
    if(self.dataSource == nil || self.dataSource.count == 0){
        return;
    }
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
#warning
//    for (NSIndexPath *indexPath in visiblePaths)
//    {
//        __block AvatarAndUsernameTableViewCell *cell = (AvatarAndUsernameTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//        PFObject *comment = self.dataSource[indexPath.row];
//        BOOL avatar = [Helper isLocalAvatarExistForUser:comment[@"senderUsername"] avatarType:AvatarTypeMid isHighRes:NO];
//        if (!avatar) {
//            [Helper getServerAvatarForUser:comment[@"senderUsername"] avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
//                cell.avatarImageView.image = image;
//            }];
//        }
//    }
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
