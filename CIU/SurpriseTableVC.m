//
//  SurpriseTableViewController.m
//  CIU
//
//  Created by Sihang Huang on 10/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "SurpriseTableVC.h"
#import "SurpriseTableViewCell.h"
#import <Parse/Parse.h>
#import "ComposeSurpriseVC.h"
#import "LogInVC.h"
#import "Helper.h"
#import "CommentVC.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "CommentVC.h"
#import <CoreData/CoreData.h>
#import "SharedDataManager.h"
#import "StatusObject.h"
#import "ComposeSurpriseVC.h"
#import "SpinnerImageView.h"
#import "NSPredicate+Utilities.h"
#import "PFQuery+Utilities.h"
#import "TabbarController.h"
#import "SVPullToRefresh.h"
#import "StatusObject+Utilities.h"
#import "ImageCollectionViewCell.h"

static float const kStatusRadius = 30;
static float const kServerFetchCount = 50;
static float const kLocalFetchCount = 20;
//static NSInteger const kSurpriseDisclaimerAlertTag = 50;
//static NSString *const kSurpriseDisclaimerKey = @"kSurpriseDisclaimerKey";
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 54.0f
static UIImage *defaultAvatar;

static NSString *const kEntityName = @"StatusObject";

@interface SurpriseTableVC () <UIAlertViewDelegate, StatusTableViewCellDelegate,UITableViewDataSource,UITableViewDelegate> {
    SurpriseTableViewCell *cellToRevive;
    UITapGestureRecognizer *tapGesture;
    CommentVC *commentVC;
    CGRect commentViewOriginalFrame;
    NSIndexPath *selectedPath;
}

@property (nonatomic, strong) NSMutableDictionary *avatarQueries;
@property (nonatomic, strong) NSMutableDictionary *postImageQueries;
@property (nonatomic, strong) NSMutableDictionary *surpriseImagesArrayByIndexPath;
@end

@implementation SurpriseTableVC

- (NSString *)keyForIndexPath:(NSIndexPath *)indexPath
{
    return [NSString stringWithFormat:@"%d:%d",(int)indexPath.row, (int)indexPath.section];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [[GAnalyticsManager shareManager] trackScreen:@"View Surprise"];
//    if (![[NSUserDefaults standardUserDefaults] objectForKey:kSurpriseDisclaimerKey]) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"亲，Surprise是一个分享美好事物的地方！不是一个约Pao、政治和生意平台，所以严禁淫秽、暴力、广告以及各种违法内容喔！也欢迎大家点击下方的感叹号图标进行举报！" delegate:self cancelButtonTitle:nil otherButtonTitles:@"同意并接受", nil];
//        alert.tag = kSurpriseDisclaimerAlertTag;
//        [alert show];
//    }

    [self addRefreshControll];
    
    [self pullDataFromLocal];
    
    if ([Reachability canReachInternet]) {
        [self fetchNewStatusWithCount:kServerFetchCount];
    }
    
    __weak SurpriseTableVC *weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf pullDataFromLocal];
        [weakSelf.tableView.infiniteScrollingView stopAnimating];
    }];
    
    self.surpriseImagesArrayByIndexPath = [NSMutableDictionary dictionary];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.tabBar.hidden = NO;
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
    }];
    [Flurry logEvent:@"View surprise" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"View surprise" withParameters:nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self fetchNewStatusWithCount:kServerFetchCount];
}

- (void)pullDataFromLocal{
    
    NSArray *fetchedObjects = [self pullDataFromLocalWithEntityName:kEntityName fetchLimit:kLocalFetchCount + _localDataCount fetchRadius:kStatusRadius];
    NSMutableArray *objectIds = [NSMutableArray arrayWithCapacity:fetchedObjects.count];
    for (StatusObject *status in fetchedObjects) {
        [objectIds addObject:status.objectId];
    }
    
    [self.tableView reloadData];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Status"];
    [query whereKey:DDObjectIdKey containedIn:objectIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            for (PFObject *pfObject in objects) {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kEntityName];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.objectId == %@", pfObject.objectId];
                NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
                if (fetchedObjects.count > 0) {
                    StatusObject *status = fetchedObjects[0];
                    status.commentCount = pfObject[DDCommentCountKey];
                }
            }
            [[SharedDataManager sharedInstance] saveContext];
            
            if (!self.tableView.isDecelerating && !self.tableView.isDragging) {
                [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows
                                      withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }];
}

-(void)fetchNewStatusWithCount:(int)count{
    
    [self setupServerQueryWithClassName:@"Status" fetchLimit:kServerFetchCount fetchRadius:kStatusRadius dateConditionKey:@"lastFetchStatusDate"];
    
    [self.fetchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error && objects.count > 0) {
            
            _serverDataCount += objects.count;
            _localDataCount += objects.count;
            
            if (!self.dataSource) {
                self.dataSource = [NSMutableArray array];
            }
            
            //construct array of indexPath and store parse data to local
            NSMutableArray *indexpathArray = [NSMutableArray array];
            
            for (int i =0; i<objects.count; i++) {
                
                PFObject *pfObject = objects[i];
                StatusObject *status = [NSEntityDescription insertNewObjectForEntityForName:kEntityName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                [status populateFromParseojbect:pfObject];
                
                [self.dataSource insertObject:status atIndex:0];
                
                [indexpathArray addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                
                if (i == objects.count - 1) {
                    [[NSUserDefaults standardUserDefaults] setObject:pfObject.createdAt forKey:@"lastFetchStatusDate"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            
            [[SharedDataManager sharedInstance] saveContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView insertRowsAtIndexPaths:indexpathArray withRowAnimation:UITableViewRowAnimationFade];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }];
}

- (void)setupServerQueryWithClassName:(NSString *)className fetchLimit:(NSUInteger)fetchLimit fetchRadius:(CGFloat)fetchRadius dateConditionKey:(NSString *)dateConditionKey
{
    if (self.fetchQuery) {
        [self.fetchQuery cancel];
        self.fetchQuery = nil;
    }
    
    NSDictionary *dictionary = [Helper userLocation];
    if (!dictionary) {
        // Without user location, don't fetch any data
        self.fetchQuery = nil;
        return;
    }
    
    // Subquries: fetch geo-bounded objects and "on top" objects
    PFQuery *geoQuery = [[PFQuery alloc] initWithClassName:className];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    [geoQuery addBoundingCoordinatesToCenter:center radius:@(fetchRadius)];
    
    PFQuery *stickyPostQuery = [[PFQuery alloc] initWithClassName:className];
    [stickyPostQuery whereKey:DDIsStickyPostKey equalTo:@YES];
    
    self.fetchQuery = [PFQuery orQueryWithSubqueries:@[geoQuery, stickyPostQuery]];
    [self.fetchQuery orderByAscending:DDCreatedAtKey];
    [self.fetchQuery whereKey:DDIsBadContentKey notEqualTo:@YES];
    
    //lastFetchStatusDate is the latest createdAt date among the statuses  last fetched
    NSDate *lastFetchDate = [[NSUserDefaults standardUserDefaults] objectForKey:dateConditionKey];
    if (lastFetchDate) {
        [self.fetchQuery whereKey:DDCreatedAtKey greaterThan:lastFetchDate];
    }
    
    // Only want to fetch kServerFetchCount items each time
    self.fetchQuery.limit = fetchLimit;
}

#pragma mark - Table view data source

#pragma mark - UITableViewDelete

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    StatusObject *status = self.dataSource[indexPath.row];
    
    __block SurpriseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.delegate = self;
    
    //message
    cell.statusCellMessageLabel.text = status.message;
    
    //username
    if (status.anonymous.boolValue) {
        cell.statusCellUsernameLabel.text = @"Anonymous";
    }else{
        cell.statusCellUsernameLabel.text = [NSString stringWithFormat:@"%@ %@",status.posterFirstName,status.posterLastName];
    }
    
    // Cell date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:status.createdAt];
    cell.statusCellDateLabel.text = str;
    
    // Comment count
    cell.commentCountLabel.text = status.commentCount.stringValue;
    
    // Flag button
    cell.flagButton.enabled = !status.isBadContent.boolValue;
    
    // Avatar
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
    
    // Collection view
    if (status.photoCount.intValue>0){
        
        cell.collectionView.hidden = NO;
        
        // Clear out old photos
        if (self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]]) {
            [self.surpriseImagesArrayByIndexPath removeObjectForKey:[self keyForIndexPath:indexPath]];
        }
        [cell.collectionView reloadData];
        
        NSMutableArray *postImages = [Helper fetchLocalPostImagesWithGenericPhotoID:status.photoID totalCount:status.photoCount.intValue isHighRes:NO];
        if (postImages.count == status.photoCount.intValue) {
            self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]] = postImages;
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
    } else {
        cell.collectionView.hidden = YES;
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
            CGRect rect = [status.message boundingRectWithSize:CGSizeMake(190, MAXFLOAT)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:@{NSFontAttributeName:[UIFont fontWithName:@"Helvetica Light" size:14]}
                                                       context:nil];
            float labelHeight = rect.size.height;
            
            //determine if there is a picture
            float pictureHeight = 0;;
            NSNumber *photoCount = status.photoCount;
            if (photoCount.intValue==0) {
                pictureHeight = 0;
            }else{
                //204 height of picture image view
                pictureHeight = [ImageCollectionViewCell imageViewHeight];
            }
            
            float cellHeight = ORIGIN_Y_CELL_MESSAGE_LABEL + labelHeight + pictureHeight + 40 + 10;//40: 10pixels btw image and flag button and 30 is the flag button height
            
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
    for (SurpriseTableViewCell *cell in self.tableView.visibleCells) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        StatusObject *status = self.dataSource[indexPath.row];
        
        if (!status.anonymous.boolValue) {
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
        } else {
            cell.statusCellAvatarImageView.image = defaultAvatar;
        }
        
        //get post image
        if(status.photoCount.intValue>0){
            
            NSMutableArray *postImages = [Helper fetchLocalPostImagesWithGenericPhotoID:status.photoID totalCount:status.photoCount.intValue isHighRes:NO];
            if (postImages.count == status.photoCount.intValue) {
                self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]] = postImages;
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
    
    __block SurpriseTableViewCell *cell = (SurpriseTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    __block StatusObject *status = self.dataSource[indexPath.row];
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"photoID" equalTo:status.photoID];
    [query whereKey:@"isHighRes" equalTo:@NO];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            if (cell==nil) {
                cell = (SurpriseTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
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
                        
                        if (!self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]]) {
                            NSMutableArray *imagesArray = [NSMutableArray array];
                            self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]] = imagesArray;
                        }
                        
                        NSMutableArray *imagesArray = self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]];
                        [imagesArray addObject:image];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [cell.collectionView reloadData];
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

#pragma mark - SurpriseTableViewCellDelegate

-(void)commentButtonTappedOnCell:(SurpriseTableViewCell *)cell{
    [[GAnalyticsManager shareManager] trackUIAction:@"buttonPress" label:@"to comment view" value:nil];
    [Flurry logEvent:@"Comment button tapped"];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    selectedPath = indexPath;
    [self performSegueWithIdentifier:@"toCommentView" sender:cell];
}

- (void)flagBadContentButtonTappedOnCell:(SurpriseTableViewCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __block StatusObject *statusObject = self.dataSource[indexPath.row];
    
    [self flagObjectForId:statusObject.objectId parseClassName:DDStatusParseClassName completion:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            statusObject.isBadContent = @YES;
            [[SharedDataManager sharedInstance] saveContext];
            cell.flagButton.enabled = NO;
        }
    }];
}

- (NSInteger)surpriseCell:(SurpriseTableViewCell *)cell collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    NSArray *images = self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:indexPath]];
    return images.count;
}

- (ImageCollectionViewCell *)surpriseCell:(SurpriseTableViewCell *)cell collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ImageCollectionViewCell *collectionViewCell = (ImageCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    // Clear out old image first
    collectionViewCell.imageView.image = nil;
    
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    NSArray *images = self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:cellIndexPath]];
    collectionViewCell.imageView.image = images[indexPath.row];
    
    return collectionViewCell;
}

- (CGSize)surpriseCell:(SurpriseTableViewCell *)cell collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
    NSArray *images = self.surpriseImagesArrayByIndexPath[[self keyForIndexPath:cellIndexPath]];
    if (indexPath.row < images.count) {
        UIImage *image = images[indexPath.row];
        CGFloat width = image.size.width < image.size.height ? [ImageCollectionViewCell imageViewHeight] / image.size.height * image.size.width : [ImageCollectionViewCell imageViewWidth];
        return CGSizeMake(width, [ImageCollectionViewCell imageViewHeight]);
    } else {
        return CGSizeZero;
    }
}

#pragma mark - Location Manager Delegate Override

//override

-(void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    [super locationManager:manager didUpdateLocation:location];
    //on viewDidLoad, fetch surprise for user once, if user wishes to see new surprises, user needs to pull down and refresh
    //on viewDidLoad, location manager may have not located the user yet, so in this method, is self.dataSource is nil or count ==0, that means we need to manually trigger fetchNewStatus
    //pull to refresh would always use the location in NSUserDefaults

//    if (self.dataSource == nil || self.dataSource.count == 0){
//        [self fetchNewStatusWithCount:20];
//    }
    
    // for surprise, we want to reload all data when:
    // this tab is first shown or there is a significant location change
    // because of the work we have done in super, this method is only going to be triggered when: first time user uses the app or there is a significant location change
    // so whenever this method is called, clear up datasource and pull from server
    self.dataSource = nil;
    [self fetchNewStatusWithCount:20];
}

#pragma mark - UISegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toCommentView"]){
        CommentVC *vc = (CommentVC *)segue.destinationViewController;
        __block StatusObject *status = self.dataSource[selectedPath.row];
        vc.statusObjectId = status.objectId;
        __weak SurpriseTableVC *weakSelf= self;
        [vc updateCommentCountWithBlock:^{
            status.commentCount = [NSNumber numberWithInt:status.commentCount.intValue+1];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[selectedPath] withRowAnimation:UITableViewRowAnimationNone];
        }];
        // This is a hack. need to do it the right way which consumes lots of time. so hold
        self.tabBarController.tabBar.hidden = YES;
    }
}

@end
