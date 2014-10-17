//
//  SurpriseTableViewController.m
//  CIU
//
//  Created by Sihang Huang on 10/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "SurpriseTableViewController.h"
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
#import "NSPredicate+Utilities.h"
#import "PFQuery+Utilities.h"
#import "TabbarController.h"

#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 86.0f
#define POST_TOTAL_LONGEVITY 1800//30 mins
static UIImage *defaultAvatar;

@interface SurpriseTableViewController () <UIAlertViewDelegate, StatusTableViewCellDelegate,UITableViewDataSource,UITableViewDelegate> {
    StatusTableViewCell *cellToRevive;
    UITapGestureRecognizer *tapGesture;
    CommentStatusViewController *commentVC;
    CGRect commentViewOriginalFrame;
    NSFetchRequest *fetchRequest;
    NSIndexPath *selectedPath;
}

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableDictionary *avatarQueries;
@property (nonatomic, strong) NSMutableDictionary *postImageQueries;

@end

@implementation SurpriseTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];

    [self addRefreshControll];
    [self fetchStatusFromLocal];
    [self fetchNewStatusWithCount:20 remainingTime:nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self fetchNewStatusWithCount:20 remainingTime:nil];
}

-(void)fetchStatusFromLocal{
    if (!fetchRequest) {
        fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"StatusObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
        [fetchRequest setEntity:entity];
        // Specify how the fetched objects should be sorted
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                       ascending:NO];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
#warning
        //        NSPredicate *predicate = [NSPredicate boundingCoordinatesToCenter:<#(CLLocationCoordinate2D)#>]
    }
    
    fetchRequest.fetchLimit = 10;
    fetchRequest.fetchOffset = self.dataSource.count;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count>0) {
        if (!self.dataSource) {
            self.dataSource = [NSMutableArray array];
        }
        [self.dataSource addObjectsFromArray:fetchedObjects];
        
        NSMutableArray *indexPathArray = [NSMutableArray array];
        for (int i =0; i<fetchedObjects.count; i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPathArray addObject:indexPath];
        }
        [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationNone];
    }
}

-(void)fetchNewStatusWithCount:(int)count remainingTime:(NSNumber *)remainingTimeInSec{
    
    __block SurpriseTableViewController *weakSelf= self;
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
                StatusObject *status = [NSEntityDescription insertNewObjectForEntityForName:@"StatusObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                status.objectId = pfObject.objectId;
                status.message = [pfObject objectForKey:@"message"];
                status.createdAt = pfObject.createdAt;
                status.picture = pfObject[@"picture"];
                status.posterUsername = pfObject[@"posterUsername"];
                status.likeCount = pfObject[@"likeCount"];
                status.commentCount = pfObject[@"commentCount"];
                status.photoCount = pfObject[@"photoCount"];
                status.photoID = pfObject[@"photoID"];
                status.anonymous = pfObject[@"anonymous"];
                [temp addObject:status];
                
                NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
                [indexpathArray addObject:path];
                
                if (i==0) {
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
        [self.refreshControl endRefreshing];
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
    
    __block StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.delegate = self;
    //pass a reference so in statusTableViewCell can use status.hash to access stuff
    //    cell.status = status;
    
    //message
    cell.statusCellMessageLabel.text = status.message;
    
    //username
    if (status.anonymous.boolValue) {
        cell.statusCellUsernameLabel.text = @"Anonymous";
    }else{
        PFUser *user = [PFUser currentUser];
        cell.statusCellUsernameLabel.text = [NSString stringWithFormat:@"%@ %@",user[@"firstName"],user[@"lastName"]];
    }
    //    cell.userNameButton.titleLabel.text = status.posterUsername;//need to set this text! used to determine if profile VC is displaying self profile or not
    //    [cell.avatarButton setTitle:status.posterUsername forState:UIControlStateNormal];
    
    //cell date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:status.createdAt];
    cell.statusCellDateLabel.text = str;
    
    //comment count
    cell.commentCountLabel.text = status.commentCount.stringValue;
    
    // Only load cached images; defer new downloads until scrolling ends. if there is no local cache, we download avatar in scrollview delegate methods
    if (!defaultAvatar) {
        defaultAvatar = [UIImage imageNamed:@"default-user-icon-profile.png"];
    }
    cell.statusCellAvatarImageView.image = defaultAvatar;
    
    if (!status.anonymous.boolValue) {
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
    }
    
    //get post image
    //clear out images for use
    cell.collectionViewImagesArray = nil;
    [cell.collectionView reloadData];
    
    if(status.photoCount.intValue>0){
        cell.collectionView.dataSource = cell;
        
        NSMutableArray *postImages = [Helper fetchLocalPostImagesWithGenericPhotoID:status.photoID totalCount:status.photoCount.intValue isHighRes:NO];
        if (postImages.count == status.photoCount.intValue) {
            cell.collectionViewImagesArray = postImages;
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
    //status.statusCellHeight defaults to 0, so cant check nil
    if (status.statusCellHeight.floatValue != 0) {
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
        if (status.statusCellHeight.floatValue != 0 ) {
            
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
        StatusObject *status = self.dataSource[indexPath.row];
        
        //get avatar
        UIImage *avatar = [Helper getLocalAvatarForUser:status.posterUsername isHighRes:NO];
        if (avatar) {
            
            cell.statusCellAvatarImageView.image = avatar;
            
        }else{
            
            PFQuery *query1 = [Helper getServerAvatarForUser:status.posterUsername isHighRes:NO completion:^(NSError *error, UIImage *image) {
                cell.statusCellAvatarImageView.image = image;
            }];
            
            if(!self.avatarQueries){
                self.avatarQueries = [NSMutableDictionary dictionary];
            }
            [self.avatarQueries setObject:query1 forKey:indexPath];
        }
        
        //get post image
        if(status.photoCount.intValue>0){
            
            NSMutableArray *postImages = [Helper fetchLocalPostImagesWithGenericPhotoID:status.photoID totalCount:status.photoCount.intValue isHighRes:NO];
            if (postImages.count == status.photoCount.intValue) {
                cell.collectionViewImagesArray = postImages;
                [cell.collectionView reloadData];
            }else{
                //get post images
                PFQuery *query2 = [self getServerPostImageForCellAtIndexpath:indexPath];
                if (!self.postImageQueries) {
                    self.postImageQueries = [NSMutableDictionary dictionary];
                }
                [self.postImageQueries setObject:query2 forKey:indexPath];
            }
        }
    }
}

-(PFQuery *)getServerPostImageForCellAtIndexpath:(NSIndexPath *)indexPath{
    
    __block StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell.statusCellPhotoImageView showLoadingActivityIndicator];
    __block StatusObject *status = self.dataSource[indexPath.row];
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"photoID" equalTo:status.photoID];
    [query whereKey:@"isHighRes" equalTo:@NO];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            if (cell==nil) {
                cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            }
            
            __block int index = status.photoCount.intValue-1;
            for (PFObject *photoObject in objects) {
                PFFile *image = photoObject[@"image"];
                [image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        
                        UIImage *image = [UIImage imageWithData:data];
                        NSString *name = [NSString stringWithFormat:@"%@%d",status.photoID,index];
                        [Helper saveImageToLocal:UIImagePNGRepresentation(image) forImageName:name isHighRes:NO];
                        index--;
                        
                        if (!cell.collectionViewImagesArray) {
                            cell.collectionViewImagesArray = [NSMutableArray array];
                        }
                        [cell.collectionViewImagesArray addObject:image];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [cell.collectionView reloadData];
                            //                            [cell.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:cell.collectionViewImagesArray.count-1 inSection:0]]];
                        });
                        
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

-(void)commentButtonTappedOnCell:(StatusTableViewCell *)cell{
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    selectedPath = indexPath;
    [self performSegueWithIdentifier:@"toCommentView" sender:cell];
}

#pragma mark - UISegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toCommentView"]){
        CommentStatusViewController *vc = (CommentStatusViewController *)segue.destinationViewController;
        __block StatusObject *status = self.dataSource[selectedPath.row];
        vc.statusObjectId = status.objectId;
        __weak SurpriseTableViewController *weakSelf= self;
        [vc updateCommentCountWithBlock:^{
            status.commentCount = [NSNumber numberWithInt:status.commentCount.intValue+1];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[selectedPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
}

@end
