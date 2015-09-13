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

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        self.internetReachability = [Reachability reachabilityForInternetConnection];
        self.wifiReachability = [Reachability reachabilityForLocalWiFi];
        self.locationManager = [Helper initLocationManagerWithDelegate:self];
        self.dataSource = [NSMutableArray array];
        [self addMenuButton];
    }
    
    return self;
}

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
    self.tableView.scrollsToTop = YES;
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

- (void)addPullDownRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(handlePullDownToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    self.refreshControl = refreshControl;

}

- (void)addInfiniteRefreshControl
{
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf handleInfiniteScroll];
    }];
}

- (NSString *)serverDataParseClassName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -serverDataParseClassName"
                                 userInfo:nil];
}

- (NSString *)localDataEntityName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -localDataEntityName"
                                 userInfo:nil];
}

- (float)dataFetchRadius
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -dataFetchRadius"
                                 userInfo:nil];
}

- (float)serverFetchCount
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -serverFetchCount"
                                 userInfo:nil];
}

- (float)localFetchCount
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -localFetchCount"
                                 userInfo:nil];
}

- (NSString *)keyForLocalDataSortDescriptor
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -keyForLocalDataSortDescriptor"
                                 userInfo:nil];
}

- (BOOL)orderLocalDataInAscending
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -orderLocalDataInAscending"
                                 userInfo:nil];
}

- (void)handleInfiniteScroll
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -handleInfiniteScroll"
                                 userInfo:nil];
}

- (void)handlePullDownToRefresh
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -handlePullDownToRefresh"
                                 userInfo:nil];
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

- (NSPredicate *)badContentPredicate
{
    return [NSPredicate predicateWithFormat:@"self.isBadContent.intValue == %d",0];
}

- (NSPredicate *)badLocalContentPredicate
{
    return [NSPredicate predicateWithFormat:@"(self.isBadContentLocal.intValue == %d) OR (self.isBadContentLocal == nil)",0];
}

- (NSPredicate *)geoBoundPredicateWithFetchRadius:(CGFloat)fetchRadius
{
    NSDictionary *dictionary = [Helper userLocation];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[DDLatitudeKey] doubleValue],
                                                              [dictionary[DDLongitudeKey] doubleValue]);
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center
                                                           radius:@(fetchRadius)];
    return [NSPredicate boudingCoordinatesPredicateForRegion:region];
}

- (NSPredicate *)stickyPostPredicate
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(self.isStickyPost.intValue == %d)", 1];
    
    return predicate;
}

- (NSPredicate *)dateRnagePredicateWithgreaterOrEqualTo:(id)greaterValue
                                        lesserOrEqualTo:(id)lesserValue
{
    if ([greaterValue compare:lesserValue] == NSOrderedDescending) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"greaterValue cannot be smaller than lesserValue"
                                     userInfo:nil];
    }
    
    NSPredicate *datePredicate = nil;
    
    if (greaterValue && !lesserValue) {
        datePredicate = [NSPredicate predicateWithFormat:@"self.createdAt > %@", greaterValue];
    } else if (!greaterValue && lesserValue) {
        datePredicate = [NSPredicate predicateWithFormat:@"self.createdAt < %@", lesserValue];
    } else if (greaterValue && lesserValue) {
        datePredicate = [NSPredicate predicateWithFormat:@"(self.createdAt > %@) AND (self.createdAt < %@)", greaterValue, lesserValue];
    }

    return datePredicate;
}

- (NSFetchRequest *)localDataFetchRequestWithEntityName:(NSString *)entityName
                                             fetchLimit:(NSUInteger)fetchLimit
                                             predicates:(NSArray *)predicates
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.includesPendingChanges = NO;
    
    // Predicate
    
    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
    [fetchRequest setPredicate:compoundPredicate];
    
    // Sort descriptor
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:[self keyForLocalDataSortDescriptor]
                                                                   ascending:[self orderLocalDataInAscending]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    fetchRequest.fetchLimit = fetchLimit;
    
    return fetchRequest;
}

- (id)valueToCompareAgainst:(id)object
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass must override -valueToCompareAgainst"
                                 userInfo:nil];
}

- (void)updateUpperBoundValueWithObject:(id)object
{
    id valueToCompare = [self valueToCompareAgainst:object];
    
    if (!valueToCompare) {
        return;
    }
    
    if ([self.greaterValue compare:valueToCompare] == NSOrderedAscending || !self.greaterValue) {
        self.greaterValue = valueToCompare;
    }
}

- (void)updateLowerBoundValueWithObject:(id)object
{
    id valueToCompare = [self valueToCompareAgainst:object];
    
    if (!valueToCompare) {
        return;
    }
    
    if ([self.lesserValue compare:valueToCompare] == NSOrderedDescending || !self.lesserValue) {
        self.lesserValue = valueToCompare;
    }
}

- (void)fetchLocalDataWithEntityName:(NSString *)entityName
                          fetchLimit:(NSUInteger)fetchLimit
                          predicates:(NSArray *)predicates
{
    if (![Helper userLocation]) {
        
        return;
    }
    
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithEntityName:entityName
                                                                  fetchLimit:fetchLimit
                                                                  predicates:predicates];
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
            
            if (i == 0) {
                [self updateUpperBoundValueWithObject:managedObject];
            }
            
            if (i == fetchedObjects.count - 1) {
                [self updateLowerBoundValueWithObject:managedObject];
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
                     greaterOrEqualTo:(id)greaterValue
                      lesserOrEqualTo:(id)lesserValue
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass must override -setupServerQueryWithClassName:fetchLimit:fetchRadius:greaterOrEqualTo:lesserOrEqualTo"
                                 userInfo:nil];
}

-(void)fetchServerDataWithParseClassName:(NSString *)parseClassName
                              fetchLimit:(NSUInteger)fetchLimit
                             fetchRadius:(CGFloat)fetchRadius
                        greaterOrEqualTo:(id)greaterValue
                         lesserOrEqualTo:(id)lesserValue{
    
    [self setupServerQueryWithClassName:parseClassName
                             fetchLimit:fetchLimit
                            fetchRadius:fetchRadius
                       greaterOrEqualTo:greaterValue
                        lesserOrEqualTo:lesserValue];
    
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
                
                // numOfGoodObjects keeps track of number of objects that doesn't have bad content
                int numOfGoodObjects = 0;
                for (int i = 0; i < objects.count; i++) {
                    
                    PFObject *pfObject = objects[i];
                    
                    if (i == 0) {
                        [self updateUpperBoundValueWithObject:pfObject];
                    }
                    
                    if (i == objects.count - 1) {
                        [self updateLowerBoundValueWithObject:pfObject];
                    }
                    
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
                    
                    
                    if ([pfObject[DDIsBadContentKey] boolValue]) {
                        continue;
                    }
                    
                    // Pull down to refresh
                    if (!greaterValue && !lesserValue) {
                        [self.dataSource addObject:managedObject];
                        [indexpathArray addObject:[NSIndexPath indexPathForRow:numOfGoodObjects inSection:0]];
                    } else if (greaterValue && !lesserValue) {
                        
                        if (!array) {
                            array = [NSMutableArray arrayWithCapacity:objects.count + self.dataSource.count];
                        }
                        [array addObject:managedObject];
                        
                        if (i == objects.count - 1) {
                            [array addObjectsFromArray:self.dataSource];
                            self.dataSource = array;
                        }
                        [indexpathArray addObject:[NSIndexPath indexPathForRow:numOfGoodObjects inSection:0]];
                    } else if (!greaterValue && lesserValue) {
                        // pull up to refresh
                        
                        [self.dataSource addObject:managedObject];
                        [indexpathArray addObject:[NSIndexPath indexPathForRow:numOfGoodObjects + originalCount inSection:0]];
                    }
                    
                    numOfGoodObjects++;
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
