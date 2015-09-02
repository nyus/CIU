//
//  GenericTableViewController.m
//  CIU
//
//  Created by Huang, Sihang on 8/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "GenericTableVC.h"
#import "Helper.h"
#import "NSPredicate+Utilities.h"
#import "PFQuery+Utilities.h"
#import "SVPullToRefresh.h"

static const CGFloat kLocationNotifyThreshold = 1.0;

@interface GenericTableVC()<UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *previousLocation;

@end

@implementation GenericTableVC

#pragma mark - Getter

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        self.wifiReachability = [Reachability reachabilityForLocalWiFi];
        self.locationManager = [Helper initLocationManagerWithDelegate:self];
        self.dataSource = [NSMutableArray array];
        [self addMenuButton];
    }
    
    return self;
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    [self addInternetObserver];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSidePanelNotification:) name:DDSidePanelNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleReachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Handler

- (void)handleSidePanelNotification:(NSNotification *)notification
{
    self.tableView.userInteractionEnabled = ![notification.userInfo[@"open"] boolValue];
}

- (void)handleReachabilityChanged:(NSNotification *)notification
{
    Reachability* reachability = [notification object];
    NSParameterAssert([reachability isKindOfClass:[Reachability class]]);
    
    // App goes from offline to online
    
    if (!self.isInternetPresentOnLaunch &&
        (reachability == self.internetReachability ||
         reachability == self.wifiReachability)) {
        self.isInternetPresentOnLaunch = YES;
    }
}

#pragma mark - Setup

- (void)addInternetObserver
{
    [self.internetReachability startNotifier];
    [self.wifiReachability startNotifier];
    self.isInternetPresentOnLaunch = [Reachability canReachInternet];
}

- (void)addRefreshControle
{
    if (!self.isInternetPresentOnLaunch) {
        [self fetchLocalDataWithEntityName:self.localDataEntityName
                                fetchLimit:self.localFetchCount
                               fetchRadius:self.dataFetchRadius
                          greaterOrEqualTo:nil
                           lesserOrEqualTo:nil];
    } else {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:nil];
    }
    
    // Pull down to refresh
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handlePullDownToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    
    // Reach tbview bottom to refresh
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        
        if (!weakSelf.isInternetPresentOnLaunch) {
            [weakSelf fetchLocalDataWithEntityName:weakSelf.localDataEntityName
                                        fetchLimit:weakSelf.localFetchCount
                                       fetchRadius:weakSelf.dataFetchRadius
                                  greaterOrEqualTo:nil
                                   lesserOrEqualTo:weakSelf.leastStatusDate];
        } else {
            [weakSelf fetchServerDataWithParseClassName:weakSelf.serverDataParseClassName
                                             fetchLimit:weakSelf.serverFetchCount
                                            fetchRadius:weakSelf.dataFetchRadius
                                       greaterOrEqualTo:nil
                                        lesserOrEqualTo:weakSelf.leastStatusDate];
        }
    }];
}

- (void)handlePullDownToRefresh
{
    if (!self.isInternetPresentOnLaunch) {
        [self fetchLocalDataWithEntityName:self.localDataEntityName
                                fetchLimit:self.localFetchCount
                               fetchRadius:self.dataFetchRadius
                          greaterOrEqualTo:self.greatestStatusDate
                           lesserOrEqualTo:nil];
    } else {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:self.greatestStatusDate
                                lesserOrEqualTo:nil];
    }
}

- (void)addMenuButton{
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"3menu"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonTapped:)];
    menuButton.accessibilityLabel = kMenuButtonAccessibilityLabel;
    self.navigationItem.leftBarButtonItem = menuButton;
}

- (void)addTapToScrollUpGesture{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBarTapped:)];
    [self.navigationController.navigationBar addGestureRecognizer:tap];
}

-(void)menuButtonTapped:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarSlideOpen" object:self];
}

-(void)navBarTapped:(id)sender{
    [self.tableView scrollsToTop];
}

-(void)loadRemoteDataForVisibleCells{
    //override by subclass
}

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{
    //override by subclass
}

- (NSArray *)objectIdsToExclude
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Need to override -objectIdsToExclude"
                                 userInfo:nil];
}

#pragma mark - Data

- (void)fetchLocalDataWithEntityName:(NSString *)entityName
                          fetchLimit:(NSUInteger)fetchLimit
                         fetchRadius:(CGFloat)fetchRadius
                    greaterOrEqualTo:(NSDate *)greaterDate
                     lesserOrEqualTo:(NSDate *)lesserDate
{
    if (![Helper userLocation] || [greaterDate compare:lesserDate] == NSOrderedDescending) {
        
        return;
    }
    
    NSDictionary *dictionary = [Helper userLocation];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.includesPendingChanges = NO;
    
    // Filter to exclude bad content
    
    NSPredicate *excludeBadContent = [NSPredicate predicateWithFormat:@"self.isBadContent.intValue == %d",0];
    NSPredicate *excludeLocalBadContent = [NSPredicate predicateWithFormat:@"self.isBadContentLocal.intValue == %d",0];
    
    // Filter by geolocation
    
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[DDLatitudeKey] doubleValue],
                                                               [dictionary[DDLongitudeKey] doubleValue]);
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center
                                                           radius:@(fetchRadius)];
    NSPredicate *predicate = [NSPredicate geoBoundAndStickyPostPredicateForRegion:region];
    
    // Filter to get data between dates
    
    NSPredicate *datePredicate = nil;
    if (greaterDate && !lesserDate) {
        datePredicate = [NSPredicate predicateWithFormat:@"self.createdAt > %@", greaterDate];
    } else if (!greaterDate && lesserDate) {
        datePredicate = [NSPredicate predicateWithFormat:@"self.createdAt < %@", lesserDate];
    } else if (greaterDate && lesserDate) {
        datePredicate = [NSPredicate predicateWithFormat:@"(self.createdAt > %@) AND (self.createdAt < %@)", greaterDate, lesserDate];
    }
    
    // Predicate
    
    NSCompoundPredicate *compoundPredicate = datePredicate ?
    [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, excludeBadContent, excludeLocalBadContent, datePredicate]] :
    [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, excludeBadContent, excludeLocalBadContent]];
    
    // Sort descriptor
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:DDCreatedAtKey
                                                                   ascending:NO];
    
    [fetchRequest setPredicate:compoundPredicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    fetchRequest.fetchLimit = fetchLimit;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest
                                                                                                     error:&error];
    
    if (fetchedObjects.count > 0) {
        
        // This has to be called before adding new objects to the data source
        
        NSUInteger currentCount = self.dataSource.count;
        NSMutableArray *indexPaths = [NSMutableArray array];
        
        for (int i = 0; i < fetchedObjects.count; i++) {
            id managedObject = fetchedObjects[i];
            [indexPaths addObject:[NSIndexPath indexPathForRow:i + currentCount inSection:0]];
            [self.dataSource addObject:managedObject];
            
            
            if (i == 0 &&
                ([self.greatestStatusDate compare:[managedObject createdAt]] == NSOrderedAscending || !self.greatestStatusDate)) {
                self.greatestStatusDate = [managedObject createdAt];
            }
            
            if (i == fetchedObjects.count - 1 &&
                ([self.leastStatusDate compare:[managedObject createdAt]] == NSOrderedDescending || !self.leastStatusDate)) {
                self.leastStatusDate = [managedObject createdAt];
            }
        }
        
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self.tableView.infiniteScrollingView stopAnimating];
    [self.refreshControl endRefreshing];
}

- (void)setupServerQueryWithClassName:(NSString *)className
                           fetchLimit:(NSUInteger)fetchLimit
                          fetchRadius:(CGFloat)fetchRadius
                     greaterOrEqualTo:(NSDate *)greaterDate
                      lesserOrEqualTo:(NSDate *)lesserDate
{
    // Override by subclass
}

-(void)fetchServerDataWithParseClassName:(NSString *)parseClassName
                              fetchLimit:(NSUInteger)fetchLimit
                             fetchRadius:(CGFloat)fetchRadius
                        greaterOrEqualTo:(NSDate *)greaterDate
                         lesserOrEqualTo:(NSDate *)lesserDate{
    
    [self setupServerQueryWithClassName:parseClassName
                             fetchLimit:fetchLimit
                            fetchRadius:fetchRadius
                       greaterOrEqualTo:greaterDate
                        lesserOrEqualTo:lesserDate];
    
    [self.fetchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [TSMessage showNotificationWithTitle:nil
                                            subtitle:NSLocalizedString(@"Oops, something went wrong, please try again", nil)
                                                type:TSMessageNotificationTypeError
                                  accessibilityLabel:@"fetchServerErrorMsg"];
                [self.tableView.infiniteScrollingView stopAnimating];
                [self.refreshControl endRefreshing];
            });
        } else {
            
            //construct array of indexPath and store parse data to local
            NSMutableArray *indexpathArray = [NSMutableArray array];
            
            if (objects.count > 0) {
                
                NSMutableArray *array = nil;
                NSInteger originalCount = self.dataSource.count;
                
                for (int i = 0; i < objects.count; i++) {
                    
                    PFObject *pfObject = objects[i];
                    
                    // Skip duplicates
                    
                    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self.localDataEntityName];
                    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.objectId == %@", pfObject.objectId];
                    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
                    id managedObject = nil;
                    
                    if (fetchedObjects.count > 0) {
                        managedObject = fetchedObjects[0];
                    } else {
                        managedObject = [NSEntityDescription insertNewObjectForEntityForName:self.localDataEntityName
                                                               inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    }
                    
                    [self populateManagedObject:managedObject fromParseObject:pfObject];
                    
                    // Pull down to refresh
                    if (!greaterDate && !lesserDate) {
                        [self.dataSource addObject:managedObject];
                        [indexpathArray addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                    } else if (greaterDate && !lesserDate) {
                        
                        if (!array) {
                            array = [NSMutableArray arrayWithCapacity:objects.count + self.dataSource.count];
                        }
                        [array addObject:managedObject];
                        
                        if (i == objects.count - 1) {
                            [array addObjectsFromArray:self.dataSource];
                            self.dataSource = array;
                        }
                        [indexpathArray addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                    } else if (!greaterDate && lesserDate) {
                        // pull up to refresh
                        
                        [self.dataSource addObject:managedObject];
                        [indexpathArray addObject:[NSIndexPath indexPathForRow:i + originalCount inSection:0]];
                    }
                    
                    if (i == 0 &&
                        ([self.greatestStatusDate compare:pfObject.createdAt] == NSOrderedAscending || !self.greatestStatusDate)) {
                        self.greatestStatusDate = pfObject.createdAt;
                    }
                    
                    if (i == objects.count - 1 &&
                        ([self.leastStatusDate compare:pfObject.createdAt] == NSOrderedDescending || !self.leastStatusDate)) {
                        self.leastStatusDate = pfObject.createdAt;
                    }
                }
                
                [[SharedDataManager sharedInstance] saveContext];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView insertRowsAtIndexPaths:indexpathArray withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView.infiniteScrollingView stopAnimating];
                [self.refreshControl endRefreshing];
            });
        }
    }];
}

-(void)populateManagedObject:(NSManagedObject *)managedObject
             fromParseObject:(PFObject *)object
{
    // Override by subclass
}

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    [self cancelRequestsForIndexpath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{}

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

#pragma mark - location manager helper

- (void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    //override by subclass
}
#pragma mark -- Location manager

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [manager startUpdatingLocation];
        NSLog(@"+++++++++++++++++++++++Start updating location+++++++++++++++++++");
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //the most recent location update is at the end of the array.
    CLLocation *location = (CLLocation *)[locations lastObject];

    //-didUpdateLocations gets called very frequently. dont fetch server until there is significant location update
    if (self.previousLocation) {
        CLLocationDistance distance = [location distanceFromLocation:self.previousLocation];
        if(distance/1609 < kLocationNotifyThreshold){
            return;
        }
    }
    self.previousLocation = location;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:location.coordinate.latitude],@"latitude",[NSNumber numberWithDouble:location.coordinate.longitude],@"longitude", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self locationManager:manager didUpdateLocation:location];
    
    NSLog(@"+++++++++++++++++++++++Did Update location: %f %f+++++++++++++++++++", location.coordinate.latitude, location.coordinate.longitude);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    NSLog(@"+++++++++++++++++++++++Updating location error: %@+++++++++++++++++++", error);
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                
                if ([CLLocationManager locationServicesEnabled]) {
                    //that means user disabled our app specifically
                    NSLog(@"fail to locate user: permission denied");
                }
                
                break;
            }
                
            case kCLErrorLocationUnknown:{
                NSLog(@"fail to locate user: location unknown");
                break;
            }
                
            default:
                NSLog(@"fail to locate user: %@",error.localizedDescription);
                break;
        }
    } else {
        // We handle all non-CoreLocation errors here
    }
}

@end
