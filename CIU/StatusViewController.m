//
//  StatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 1/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "StatusViewController.h"
#import "StatusTableViewCell.h"
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
#import "ComposeNewStatusViewController.h"
#import "SpinnerImageView.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
#define POST_TOTAL_LONGEVITY 1800//30 mins
@interface StatusViewController ()<UIActionSheetDelegate, MFMailComposeViewControllerDelegate,UIAlertViewDelegate, StatusTableViewCellDelegate,UITableViewDataSource,UITableViewDelegate>{
    
    StatusTableViewCell *cellToRevive;
    UIRefreshControl *refreshControl;
    UITapGestureRecognizer *tapGesture;
    CommentStatusViewController *commentVC;
    NSString *statusIdToPass;
    CGRect commentViewOriginalFrame;
}

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableDictionary *avatarQueries;
@property (nonatomic, strong) NSMutableDictionary *postImageQueries;
@end

@implementation StatusViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view = self.tableView;
    //add refresh control
    [self addRefreshControll];
}

-(void)viewWillAppear:(BOOL)animated{
    //add right bar item(compose)
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonTapped:)];
    UITabBarController *tab=self.navigationController.viewControllers[0];
    tab.navigationItem.rightBarButtonItem = item;
}

-(void)composeButtonTapped:(UIBarButtonItem *)sender{
    ComposeNewStatusViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"composeStatus"];
    [self presentViewController:vc animated:YES completion:nil];
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
    [self fetchNewStatusWithCount:20 remainingTime:nil];
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    __block StatusViewController *weakSelf= self;
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    query.limit = count;
    [query orderByDescending:@"createdAt"];
    //lastFetchStatusDate is the latest createdAt date among the statuses  last fetched
    NSDate *lastFetchStatusDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastFetchStatusDate"];
    if (lastFetchStatusDate) {
        [query whereKey:@"createdAt" greaterThan:lastFetchStatusDate];
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (objects.count != 0) {
            
            if (!weakSelf.dataSource) {
                weakSelf.dataSource = [NSMutableArray array];
            }
            
            //the purpose of temp is to make sure last created status goes to the top of the tableivew with an algo of O(n). if we insert new items into the old array, it would be O(n^2)
            NSMutableArray *temp = [NSMutableArray array];
            
            //construct array of indexPath and store parse data to local
            NSMutableArray *indexpathArray = [NSMutableArray array];
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
                
                [temp addObject:status];
                
                NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                [indexpathArray addObject:path];
                
                if (i==objects.count-1) {
                    [[NSUserDefaults standardUserDefaults] setObject:pfObject.createdAt forKey:@"lastFetchStatusDate"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            //the purpose of temp is to make sure last created status goes to the top of the tableivew with an algo of O(n). if we insert new items into the old array, it would be O(n^2)
            [temp addObjectsFromArray:weakSelf.dataSource];
            weakSelf.dataSource = nil;
            weakSelf.dataSource = temp;
            
            [[SharedDataManager sharedInstance] saveContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView beginUpdates];
                [weakSelf.tableView insertRowsAtIndexPaths:indexpathArray withRowAnimation:UITableViewRowAnimationFade];
                [weakSelf.tableView endUpdates];
            });
            
        }else{
            //
            NSLog(@"0 items fetched from parse");
        }
        [refreshControl endRefreshing];
    }];
}

#pragma mark - Table view data source

#pragma mark - UITableViewDelete

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.dataSource.count;
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    StatusObject *status = self.dataSource[indexPath.row];
    
    __block StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageAndPhotoCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.delegate = self;
    //pass a reference so in statusTableViewCell can use status.hash to access stuff
    //    cell.status = status;
    
    //message
    cell.statusCellMessageLabel.text = status.message;
    
    //username
    cell.statusCellUsernameLabel.text = status.posterUsername;
    cell.userNameButton.titleLabel.text = status.posterUsername;//need to set this text! used to determine if profile VC is displaying self profile or not
    [cell.avatarButton setTitle:status.posterUsername forState:UIControlStateNormal];
    
    //cell date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:status.createdAt];
    cell.statusCellDateLabel.text = str;
    
    //comment count
    cell.commentCountLabel.text = status.commentCount.stringValue;
    
    
    // Only load cached images; defer new downloads until scrolling ends. if there is no local cache, we download avatar in scrollview delegate methods
    cell.statusCellAvatarImageView.image = [UIImage imageNamed:@"default-user-icon-profile.png"];
    UIImage *avatar = [Helper getLocalAvatarForUser:status.posterUsername isHighRes:NO];
    if (avatar) {
        cell.statusCellAvatarImageView.image = avatar;
    }else{
        if (tableView.isDecelerating == NO && tableView.isDragging == NO) {
           PFQuery *query = [Helper getServerAvatarForUser:status.posterUsername isHighRes:NO completion:^(NSError *error, UIImage *image) {
                cell.statusCellAvatarImageView.image = image;
            }];
            
            if(!self.avatarQueries){
                self.avatarQueries = [NSMutableDictionary dictionary];
            }
            [self.avatarQueries setObject:query forKey:indexPath];
        }
    }
    
    //get post image
    if(status.photoCount.intValue>0){
        cell.collectionView.dataSource = cell;
        if (cell.collectionViewImagesArray!=nil) {
            [cell.collectionView reloadData];
        }else{
            
            if (tableView.isDecelerating == NO && tableView.isDragging == NO){
                PFQuery *query = [self getServerPostImageForCellAtIndexpath:indexPath];
                if (!self.postImageQueries) {
                    self.postImageQueries = [NSMutableDictionary dictionary];
                }
                [self.postImageQueries setObject:query forKey:indexPath];
            }
        }
    }
    return cell;
}


-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    StatusObject *status = self.dataSource[indexPath.row];
    if (status.statusCellHeight) {
        return status.statusCellHeight.floatValue;
    }else{
        return 200;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{
        
        StatusObject *status = self.dataSource[indexPath.row];
        
        //is cell height has been calculated, return it
        if (status.statusCellHeight) {
            
            return status.statusCellHeight.floatValue;
            
        }else{
            
            //determine height of label(message must exist)
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
            //number of lines must be set to zero so that sizeToFit would work correctly
            label.numberOfLines = 0;
            label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17];
            label.text = [status message];
            CGSize aSize = [label sizeThatFits:label.frame.size];
            
            float labelHeight = aSize.height;//ceilf(ceilf(size.width) / CELL_MESSAGE_LABEL_WIDTH)*ceilf(size.height)+10;
            
            //determine if there is a picture
            float pictureHeight = 0;;
            NSNumber *photoCount = status.photoCount;
            if (photoCount.intValue==0) {
                pictureHeight = 0;
            }else{
                //204 height of picture image view
                pictureHeight = 204;
            }
            
            float cellHeight = ORIGIN_Y_CELL_MESSAGE_LABEL + labelHeight;
            if (pictureHeight !=0) {
                cellHeight += 10 + pictureHeight;
            }
            
            cellHeight = cellHeight+10;
            
            status.statusCellHeight = [NSNumber numberWithFloat:cellHeight];
            return cellHeight;
        }
    }
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    [self cancelNetworkRequestForCell:cell atIndexPath:indexPath];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadRemoteDataForVisibleCells];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self loadRemoteDataForVisibleCells];
    }
}

-(void)loadRemoteDataForVisibleCells{
    for (StatusTableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        //get avatar
        StatusObject *status = self.dataSource[indexPath.row];
        PFQuery *query1 = [Helper getServerAvatarForUser:status.posterUsername isHighRes:NO completion:^(NSError *error, UIImage *image) {
            cell.statusCellAvatarImageView.image = image;
        }];
        
        if(!self.avatarQueries){
            self.avatarQueries = [NSMutableDictionary dictionary];
        }
        [self.avatarQueries setObject:query1 forKey:indexPath];
        
        //get post images
        PFQuery *query2 = [self getServerPostImageForCellAtIndexpath:indexPath];
        if (!self.postImageQueries) {
            self.postImageQueries = [NSMutableDictionary dictionary];
        }
        [self.postImageQueries setObject:query2 forKey:indexPath];
    }
}

-(PFQuery *)getServerPostImageForCellAtIndexpath:(NSIndexPath *)indexPath{
    
    __block StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.statusCellPhotoImageView showLoadingActivityIndicator];
    Status *status = self.dataSource[indexPath.row];
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
#warning
//    [query whereKey:@"status" equalTo:status.pfObject];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            if (cell==nil) {
                cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            }
            for (PFObject *photoObject in objects) {
                PFFile *image = photoObject[@"image"];
                [image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        NSLog(@"add items for indexpath %@",indexPath);
                        
                        UIImage *image = [UIImage imageWithData:data];
                        if (!cell.collectionViewImagesArray) {
                            cell.collectionViewImagesArray = [NSMutableArray array];
                        }
                        NSLog(@"add photo for indexpath: %@",indexPath);
                        [cell.collectionViewImagesArray addObject:image];
                        [cell.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:cell.collectionViewImagesArray.count-1 inSection:0]]];
                    }
                }];
            }
        }
    }];
    
    return query;
}

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    PFQuery *avatarQ = [self.avatarQueries objectForKey:indexPath];
    PFQuery *postimageQ = [self.postImageQueries objectForKey:indexPath];
    if (avatarQ) {
        [avatarQ cancel];
        [self.avatarQueries removeObjectForKey:indexPath];
    }
    if (postimageQ) {
        [postimageQ cancel];
        [self.postImageQueries removeObjectForKey:indexPath];
    }
}

#pragma mark - StatusTableCellDelegate

-(void)swipeGestureRecognizedOnCell:(StatusTableViewCell *)cell{

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    if (self.dataSource==nil || indexPath.row>=self.dataSource.count) {
        return;
    }
    
    StatusObject *status = self.dataSource[indexPath.row];
    
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
    commentVC.statusObjectId = status.objectId;
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
