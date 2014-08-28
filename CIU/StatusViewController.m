//
//  StatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 1/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "StatusViewController.h"
#import "StatusTableViewCell.h"
#import "Status.h"
#import <Parse/Parse.h>
#import "ComposeNewStatusViewController.h"
#import "LogInViewController.h"
#import "Helper.h"
#import "CommentStatusViewController.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "FPLogger.h"
#import "CommentStatusViewController.h"
#import <CoreData/CoreData.h>
#import "SharedDataManager.h"
#import "StatusObject.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
#define POST_TOTAL_LONGEVITY 1800//30 mins
@interface StatusViewController ()<StatusObjectDelegate,UIActionSheetDelegate, MFMailComposeViewControllerDelegate,UIAlertViewDelegate>{
    
    StatusTableViewCell *cellToRevive;
    UIRefreshControl *refreshControl;
    UITapGestureRecognizer *tapGesture;
    CommentStatusViewController *commentVC;
    NSString *statusIdToPass;
    CGRect commentViewOriginalFrame;
}


@end

@implementation StatusViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    [self.view addGestureRecognizer:tapGesture];
    
    //add refresh control
    [self addRefreshControll];
    
    //register for UIApplicationWillEnterForegroundNotification notification since timer will not work in the background for more than 10 mins. when user comes back, we refresh table view to update the status count down time
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)handleApplicationWillEnterForeground{
//    [self fetchNewStatusWithCount:25 remainingTime:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    //stop observing UIApplicationWillEnterForegroundNotification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addRefreshControll{
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self fetchNewStatusWithCount:25 remainingTime:nil];
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    
    __block StatusViewController *weakSelf= self;
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    query.limit = count;
    [query orderByDescending:@"createdAt"];
    NSDate *lastFetchStatusDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastFetchStatusDate"];
    if (lastFetchStatusDate) {
        [query whereKey:@"createdAt" greaterThan:lastFetchStatusDate];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count != 0) {
            
            if (!weakSelf.dataSource) {
                weakSelf.dataSource = [NSMutableArray array];
            }
            
            //construct array of indexPath and store parse data to local
            NSMutableArray *indexpathArray = [NSMutableArray array];
            int originalCount = weakSelf.dataSource.count;
            for (int i =0; i<objects.count; i++) {
                
                PFObject *pfObject = objects[i];
                StatusObject *status = [NSEntityDescription insertNewObjectForEntityForName:@"LifestyleObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                status.objectId = pfObject.objectId;
                status.message = [pfObject objectForKey:@"message"];
                status.createdAt = pfObject.createdAt;
                status.picture = pfObject[@"picture"];
                status.posterUsername = pfObject[@"posterUsername"];
                status.likeCount = pfObject[@"likeCount"];
                status.commentCount = pfObject[@"commentCount"];
                status.photoCount = pfObject[@"photoCount"];
                
//                [status populateFromObject:parseObject];
                
                NSIndexPath *path = [NSIndexPath indexPathForRow:i+originalCount inSection:0];
                [indexpathArray addObject:path];
                
                [weakSelf.dataSource addObject:status];
            }
            
            [[SharedDataManager sharedInstance] saveContext];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView beginUpdates];
                if (originalCount != [weakSelf.tableView numberOfRowsInSection:0]) {
                    //remove the loading cell
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[weakSelf.tableView numberOfRowsInSection:0]-1 inSection:0];
                    [weakSelf.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
                }
                [weakSelf.tableView insertRowsAtIndexPaths:indexpathArray withRowAnimation:UITableViewRowAnimationFade];
                [weakSelf.tableView endUpdates];
            });
            
        }else{
            //
            NSLog(@"0 items fetched from parse");
        }
        [refreshControl endRefreshing];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastFetchStatusDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }];
}

#pragma mark - Status Object Delegate Timer Count Down

-(void)statusObjectTimeUpWithObject:(Status *)object{
    NSInteger index = [self.dataSource indexOfObject:object];
    StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    if ([cell.statusCellMessageLabel.text isEqualToString:object.message]) {
        //        [cell blurCell];
        [self removeStoredHeightForStatus:object];
        [self.dataSource removeObject:object];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        //if there is no status anymore, need to reload to show the background cell
        if(self.dataSource.count == 0){
            //setting self.dataSource to nil prevents talbeview from crashing.
            self.dataSource = nil;
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
//    return [super numberOfSectionsInTableView:tableView];
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //for non background cell
    if(self.dataSource && self.dataSource.count != 0){
        [[self.dataSource objectAtIndex:indexPath.row] startTimer];
        
        //update the count down text
        StatusTableViewCell *scell = (StatusTableViewCell *)cell;
        Status *object = self.dataSource[indexPath.row];
        if ([scell.statusCellMessageLabel.text isEqualToString: object.message] && object.countDownTime == 0) {
            
            [self.dataSource removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            
            if(self.dataSource.count == 0){
                self.dataSource = nil;
                [self.tableView reloadData];
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44.0f;
}

#pragma mark - StatusTableCellDelegate

-(void)swipeGestureRecognizedOnCell:(StatusTableViewCell *)cell{

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (self.dataSource==nil || indexPath.row>=self.dataSource.count) {
        return;
    }
    
    Status *status = self.dataSource[indexPath.row];
    
    if (!commentVC) {
        commentVC = [self.storyboard instantiateViewControllerWithIdentifier:@"commentView"];
        commentViewOriginalFrame = commentVC.view.frame;
        commentVC.view.frame = CGRectMake(320, 200, 50, 50);
        commentVC.animateEndFrame = CGRectMake(320, cell.frame.origin.y-44, 320, cell.frame.size.height);
        commentVC.statusVC = self;
        [self.view addSubview:commentVC.view];
    }
    [commentVC clearCommentTableView];
    commentVC.statusTBCell = cell;
    commentVC.statusObjectId = status.objectid;
    commentVC.view.frame = CGRectMake(320, cell.frame.origin.y-44, 320, cell.frame.size.height);
    //dont allow interaction with tableview
    self.tableView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionTransitionNone animations:^{
        
        self.shadowView.alpha = 0.55f;
        commentVC.view.frame = CGRectMake(0, 100, commentViewOriginalFrame.size.width,300);//commentViewOriginalFrame.size.height-50);
        [commentVC.view layoutIfNeeded];
    } completion:^(BOOL finished) {
//        [commentVC.view layoutIfNeeded];
    }];
}

-(void)usernameLabelTappedOnCell:(StatusTableViewCell *)cell{
    [self performSegueWithIdentifier:@"toUserProfile" sender:self];
}

-(int)convertCountDownTextToSecond:(NSString *)coundDownText{
    NSArray *components = [coundDownText componentsSeparatedByString:@":"];
    
    int min = [[components objectAtIndex:0] intValue];
    int sec = [[components objectAtIndex:1] intValue];
    
    return min*60+sec;
}

-(void)commentButtonTappedOnCell:(StatusTableViewCell *)cell{
    
    [self swipeGestureRecognizedOnCell:cell];

}

-(void)reviveAnimationDidEndOnCell:(StatusTableViewCell *)cell withProgress:(float)percentage{
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Status *status = self.dataSource[indexPath.row];
    int timeToAdd = (POST_TOTAL_LONGEVITY - status.countDownTime)*percentage;
    
    //add time to the status locally
    status.countDownTime += timeToAdd;
    NSLog(@"percentage %f, added %d seconds",percentage, timeToAdd);
    //
    PFQuery *queryStatusObj = [[PFQuery alloc] initWithClassName:@"Status"];
    [queryStatusObj whereKey:@"objectId" equalTo:status.objectid];
    [queryStatusObj getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            object[@"expirationTimeInSec"] = [NSNumber numberWithInt:status.countDownTime];
            object[@"expirationDate"] = [NSDate dateWithTimeInterval:status.countDownTime sinceDate:[NSDate date]];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [FPLogger record:[NSString stringWithFormat:@"revive status: %@ succeeded",object]];
                }else{
                    [FPLogger record:[NSString stringWithFormat:@"revive status: %@ failed",object]];
                }
            }];
        }else{
            [FPLogger record:[NSString stringWithFormat:@"cannot find post with id %@ to revive",object.objectId]];
        }
    }];
    
    //add 1 to the revive count
    int reviveCount = cell.reviveCountLabel.text.intValue;
    cell.reviveCountLabel.text = [NSString stringWithFormat:@"%d",reviveCount+1];
    [status.pfObject setObject:[NSNumber numberWithInt:reviveCount+1] forKey:@"reviveCount"];
    [status.pfObject saveInBackground];
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    //0:About 1:Contact 2:Log out
    if (buttonIndex == 0) {
        
    }else if (buttonIndex == 1){
        MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
        [vc setToRecipients:@[@"dwndlr@gmail.com"]];
        vc.mailComposeDelegate = self;

        [self presentViewController:vc animated:YES completion:nil];
    }else if (buttonIndex == 2){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you want to log out?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Log out", nil];
        [alert show];
    }else if (buttonIndex == 3){
        [FPLogger sendReport];
    }
}

#pragma mark - UISegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toCommentStatus"]){
        CommentStatusViewController *vc = (CommentStatusViewController *)segue.destinationViewController;
        vc.statusObjectId = statusIdToPass;
    }
}

#pragma mark - MFMail

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    //log out alert
    if (buttonIndex == 1) {
        [PFUser logOut];
        LogInViewController *vc = (LogInViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"logInView"];
        [self presentViewController:vc animated:NO completion:nil];
    }
}
@end
