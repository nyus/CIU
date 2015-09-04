//
//  LifestyleDetailViewController.m
//  CIU
//
//  Created by Huang, Sihang on 8/22/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleDetailVC.h"
#import <CoreLocation/CoreLocation.h>
#import "Masonry.h"
#import "Query.h"
#import "SharedDataManager.h"
#import "NSString+Map.h"
#import <Parse/Parse.h>
#import "NSPredicate+Utilities.h"
#import "LifestyleObject.h"
#import "LifestyleObject+Utilities.h"
#import "CustomMKPointAnnotation.h"
#import "LifestyleObjectDetailTableVC.h"
#import "PFQuery+Utilities.h"
#import "Helper.h"
#import "ComposeVC.h"
#import "LoadingTableViewCell.h"
#import "JobTradeTableViewCell.h"
#import "DisplayPeripheralHeaderView.h"
#import "NameAddressTableViewCell.h"

#define MILE_PER_DELTA 69.0
#define IS_JOB_TRADE self.categoryType == DDCategoryTypeJob || self.categoryType == DDCategoryTypeTradeAndSell
#define IS_JOB self.categoryType == DDCategoryTypeJob
#define IS_TRADE self.categoryType == DDCategoryTypeTradeAndSell
#define IS_RES_MARKT self.categoryType == DDCategoryTypeRestaurant || self.categoryType == DDCategoryTypeSupermarket
#define IS_RESTAURANT self.categoryType == DDCategoryTypeRestaurant
#define IS_MARKET self.categoryType == DDCategoryTypeSupermarket

NSInteger const kRefreshControlTag = 31;
static const CGFloat kLocationNotifyThreshold = 1.0;
static NSString *const kSupermarketDataRadiusKey = @"kSupermarketDataRadius";
static NSString *const kRestaurantDataRadiusKey = @"kRestaurantDataRadiusKey";
static NSString *const kTradeAndSellDataRadiusKey = @"kTradeAndSellDataRadiusKey";

static NSString *const kNameAndAddressCellReuseID = @"kNameAndAddressCellReuseID";
static NSString *const kJobAndTradeCellReuseID = @"kJobAndTradeCellReuseID";
static NSString *const kToObjectDetailVCSegueID = @"toObjectDetail";

@interface LifestyleDetailVC()<LoadingTableViewCellDelegate,CLLocationManagerDelegate,MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate, JobTradeTableViewCellDelegate>{
    BOOL mapRenderedOnStartup;
    LifestyleObject *lifestyleToPass;
    CLLocation *previousLocation;
    BOOL isOffline;
    BOOL forceReload;
}

@property (nonatomic, strong) DisplayPeripheralHeaderView *headerView;
@property (nonatomic, strong) Query *query;
@property (nonatomic, strong) PFQuery *pfQuery;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;
@property (nonatomic, strong) NSMutableArray *tableViewDataSource;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIButton *reResearchButton;
@property (nonatomic, assign) BOOL isMapLoaded;

@end

@implementation LifestyleDetailVC

#pragma mark - Set and get data radius

- (NSString *)getDataRadiusKeyWithCategoryType:(DDCategoryType)categoryType
{
    switch (categoryType) {
        case DDCategoryTypeRestaurant:
            return kRestaurantDataRadiusKey;
            break;
        case DDCategoryTypeSupermarket:
            return kSupermarketDataRadiusKey;
            break;
        case DDCategoryTypeTradeAndSell:
            return kTradeAndSellDataRadiusKey;
            break;
        default:
            return nil;
            break;
    }
}

- (NSNumber *)getDataRadiusWithKey:(NSString *)key
{
    if ([key isEqualToString:kTradeAndSellDataRadiusKey]) {
        return [self tradeAndSellDataRadius];
    } else if ([key isEqualToString:kRestaurantDataRadiusKey]) {
        return [self restaurantDataRadius];
    } else if ([key isEqualToString:kSupermarketDataRadiusKey]) {
        return [self supermarketDataRadius];
    } else {
        return nil;
    }
}

- (NSNumber *)tradeAndSellDataRadius
{
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kTradeAndSellDataRadiusKey];
    if (!radius) {
        [self setDataRadius:@5 forKey:kTradeAndSellDataRadiusKey];
        return @5;
    } else {
        return radius;
    }
}

- (NSNumber *)restaurantDataRadius
{
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kRestaurantDataRadiusKey];
    if (!radius) {
        [self setDataRadius:@5 forKey:kRestaurantDataRadiusKey];
        return @5;
    } else {
        return radius;
    }
}

- (NSNumber *)supermarketDataRadius
{
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kSupermarketDataRadiusKey];
    if (!radius) {
        [self setDataRadius:@5 forKey:kSupermarketDataRadiusKey];
        return @5;
    } else {
        return radius;
    }
}

- (void)setDataRadius:(NSNumber *)newRadius forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:newRadius forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (DisplayPeripheralHeaderView *)headerView
{
    if (!_headerView) {
        NSString *key = [self getDataRadiusKeyWithCategoryType:self.categoryType];
        NSNumber *radius = [self getDataRadiusWithKey:key];
        _headerView = [[DisplayPeripheralHeaderView alloc] initWithCurrentValue:radius
                                                                      stepValue:@(5.0)
                                                                   minimunValue:@(5.0)
                                                                   maximunValue:@(30.0)
                                                                    contentMode:ContentModeLeft
                                                                    actionBlock:^(double newValue) {
                                                                        [self setDataRadius:@(newValue) forKey:key];
                                                                        [self handleDataDisplayPeripheral:newValue];
                                                                    }];
    }
    
    return _headerView;
}

-(UIButton *)reResearchButton
{
    if (!_reResearchButton) {
        _reResearchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _reResearchButton.layer.cornerRadius = 10.0;
        _reResearchButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _reResearchButton.layer.borderWidth = 1.0;
        [_reResearchButton setTitle:@"Redo search in this area" forState:UIControlStateNormal];
        [_reResearchButton setTitleColor:[UIColor themeTextGrey] forState:UIControlStateNormal];
        _reResearchButton.titleLabel.font = [UIFont themeFontWithSize:18.0];
        _reResearchButton.hidden = YES;
        _reResearchButton.backgroundColor = [UIColor themeGreen];
        [_reResearchButton addTarget:self
                              action:@selector(reSearchButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
        [_mapView addSubview:_reResearchButton];
        
        [_reResearchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(240.0));
            make.centerX.equalTo(_mapView);
            make.height.equalTo(@(44.0));
            make.bottom.equalTo(@(-10));
        }];
    }
    
    return _reResearchButton;
}

- (void)reSearchButtonTapped:(UIButton *)reSearchButton
{
    
    [[GAnalyticsManager shareManager] trackUIAction:@"buttonPress" label:[NSString stringWithFormat:@"%@-Redo search in map", IS_RESTAURANT ? @"Restaurant" : @"Supermarket"] value:nil];
    [Flurry logEvent:[NSString stringWithFormat:@"%@-Redo search in map", IS_RESTAURANT ? @"Restaurant" : @"Supermarket"]];
    [self fetchLocalDataWithRegion:self.mapView.region];
    [self fetchServerDataWithRegion:self.mapView.region];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem.accessibilityLabel = @"Back";
    
    [self.tableView registerClass:[NameAddressTableViewCell class] forCellReuseIdentifier:kNameAndAddressCellReuseID];
    [self.tableView registerClass:[JobTradeTableViewCell class] forCellReuseIdentifier:kJobAndTradeCellReuseID];
    
    // Note: empty back button title is set in IB. Select navigation bar in LifestyleTableViewController. The tilte is set to an empty string.
    
    isOffline = ![Reachability canReachInternet];

    if (IS_RES_MARKT) {
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"List",@"Map"]];
        [self.segmentedControl addTarget:self
                             action:@selector(segmentedControlTapped:)
                   forControlEvents:UIControlEventValueChanged];
        self.segmentedControl.selectedSegmentIndex = 0;
        self.segmentedControl.accessibilityLabel = kListMapSegmentedControlAccessibilityLabel;
        
        self.navigationItem.titleView = self.segmentedControl;
        
        [[GAnalyticsManager shareManager] trackScreen:IS_RESTAURANT ? @"Restaurant" : @"SuperMarket"];
        
    }else if (IS_JOB_TRADE) {
        
        if (IS_JOB) {
            self.title = @"Jobs";
        } else {
            self.title = @"Trade & Sell";
        }
        
        [[GAnalyticsManager shareManager] trackScreen:IS_JOB ? @"Job" : @"Trade & Sell"];
        
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
        self.navigationItem.rightBarButtonItem = rightItem;
        
        [self addRefreshControl];
    }
    
    [self fetchData];
}

- (void)addRefreshControl
{
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refreshControlTriggerred:) forControlEvents:UIControlEventValueChanged];
    refreshControl.tag = kRefreshControlTag;
    [self.tableView addSubview:refreshControl];
}

- (void)fetchData
{
    NSNumber *rememberedRadius = IS_RESTAURANT ? [self restaurantDataRadius] : [self supermarketDataRadius];
    if(isOffline){
        [self fetchLocalDataForListWithRadius:rememberedRadius categoryType:self.categoryType];
        
    }else{
        if (IS_JOB) {
            //jobs, trade and sell don't need location info yet
            [self fetchServerDataForListAroundCenter:CLLocationCoordinate2DMake(0, 0)
                                              raidus:rememberedRadius
                                        categoryType:self.categoryType];
            
        }else {
            self.locationManager = [Helper initLocationManagerWithDelegate:self];
            
            BOOL authorized = IS_IOS_8 ? [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse : YES;
            if (authorized) {
                NSDictionary *userLocation = [Helper userLocation];
                CLLocationCoordinate2D coor = CLLocationCoordinate2DMake([userLocation[@"latitude"] doubleValue], [userLocation[@"longitude"] doubleValue]);
                [self fetchServerDataForListAroundCenter:coor
                                                  raidus:rememberedRadius
                                            categoryType:self.categoryType];
            }
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
    }];
    if (IS_RESTAURANT) {
        [Flurry logEvent:@"View restaurant" timed:YES];
    }else if (IS_MARKET){
        [Flurry logEvent:@"View supermarket" timed:YES];
    }else if (IS_JOB){
        [Flurry logEvent:@"View job" timed:YES];
    }else{
        [Flurry logEvent:@"View trade and sell" timed:YES];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.mapView.showsUserLocation = NO;
    if (IS_RESTAURANT) {
        [Flurry endTimedEvent:@"View restaurant" withParameters:nil];
    }else if (IS_MARKET){
        [Flurry endTimedEvent:@"View supermarket" withParameters:nil];
    }else if (IS_JOB){
        [Flurry endTimedEvent:@"View job" withParameters:nil];
    }else{
        [Flurry endTimedEvent:@"View trade and sell" withParameters:nil];
    }
}

- (void)refreshControlTriggerred:(UIRefreshControl *)sender
{
    [self fetchData];
}

-(void)addButtonTapped:(UIBarButtonItem *)sender{
    UINavigationController *vc = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"compose"];
    ComposeVC *compose = (ComposeVC *)vc.topViewController;
    compose.categoryType = self.categoryType;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)segmentedControlTapped:(UISegmentedControl *)sender{
    //list view
    if (sender.selectedSegmentIndex==0) {
        [UIView animateWithDuration:.3 animations:^{
            self.tableView.alpha = 1.0f;
            self.mapView.alpha = 0.0f;
        }];
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect" label:IS_RESTAURANT ? @"Restaurant-list" : @"Supermarket-list" value:nil];
        [Flurry logEvent:@"Switch to list view" withParameters:@{@"screen":IS_RESTAURANT ? @"Restaurant" : @"Supermarket"}];
    }else{
    //map view
        self.mapView.showsUserLocation = YES;
        [UIView animateWithDuration:.3 animations:^{
            self.tableView.alpha = 0.0f;
            self.mapView.alpha = 1.0f;
        }];
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect" label:IS_RESTAURANT ? @"Restaurant-map" : @"Supermarket-map" value:nil];
        [Flurry logEvent:@"Switch to map view" withParameters:@{@"screen":IS_RESTAURANT ? @"Restaurant" : @"Supermarket"}];
    }
}

- (NSFetchRequest *)localDataFetchRequestWithRegion:(MKCoordinateRegion)region
                                       categoryType:(DDCategoryType)categoryType
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LifestyleObject"];
    // Predicate
    NSPredicate *excludeBadContent = [NSPredicate predicateWithFormat:@"self.isBadContent == %@", @NO];
    NSPredicate *excludeLocalBadContent = [NSPredicate predicateWithFormat:@"(self.isBadContentLocal.intValue == %d) OR (self.isBadContentLocal == nil)",0];
    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@",[LifestyleCategory getParseClassNameForCategoryType:self.categoryType]];
    if (categoryType != DDCategoryTypeJob) {
        NSPredicate *geoLocation = [NSPredicate boudingCoordinatesPredicateForRegion:region];
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludeBadContent, excludeLocalBadContent, geoLocation, categoryPredicate]];
    } else {
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludeBadContent, excludeLocalBadContent, categoryPredicate]];
    }
    // Sort descriptor
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    return fetchRequest;
}

-(void)fetchLocalDataWithRegion:(MKCoordinateRegion)region{
    
    self.mapViewDataSource = nil;
    self.mapViewDataSource = [NSMutableArray array];
    
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithRegion:region
                                                            categoryType:self.categoryType];
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count>0) {
        
        [self.mapViewDataSource addObjectsFromArray:fetchedObjects];
        
        //new annotaions to add
        NSMutableArray *coors = [NSMutableArray array];
        for (LifestyleObject * managedObject in fetchedObjects) {

            CustomMKPointAnnotation *pin = [[CustomMKPointAnnotation alloc] init];
            pin.coordinate = CLLocationCoordinate2DMake(managedObject.latitude.doubleValue, managedObject.longitude.doubleValue);
            pin.title = managedObject.name;
            pin.subtitle = managedObject.category;
            pin.lifetstyleObject = managedObject;
            pin.needAnimation = NO;
            [coors addObject:pin];
            
        }
        [self.mapView addAnnotations:coors];
    }
}

-(void)fetchServerDataWithRegion:(MKCoordinateRegion)region{
    
    if (self.query) {
        [self.query cancelRequest];
        self.query = nil;
    }
    
    NSString *parseClassName = [LifestyleCategory getParseClassNameForCategoryType:self.categoryType];
    if (parseClassName==nil) {
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.query = [[Query alloc] init];
    [self.query fetchObjectsOfClassName:parseClassName region:region completion:^(NSError *error, NSArray *results) {
        if (!error && results.count>0) {
            
            NSMutableDictionary *map;
            for (int i =0; i<self.mapViewDataSource.count; i++) {
                if (!map) {
                    map = [NSMutableDictionary dictionary];
                }
                LifestyleObject *life = self.mapViewDataSource[i];
                [map setValue:[NSNumber numberWithInt:i] forKey:life.objectId];
            }
            
            //new annotaions to add
            NSMutableArray *coors = [NSMutableArray array];
            
            for (PFObject *object in results) {
                
                NSNumber *lifeIndex = [map valueForKey:object.objectId];
                if (lifeIndex) {
                    //update value
                    LifestyleObject *life = self.mapViewDataSource[lifeIndex.intValue];
                    if ([life.updatedAt compare:object.updatedAt] == NSOrderedAscending) {
                        [life populateFromObject:object];
                    }
                }else{
                    //insert new item
                    LifestyleObject *life = [NSEntityDescription insertNewObjectForEntityForName:@"LifestyleObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [life populateFromObject:object];
                    [self.mapViewDataSource addObject:life];
                    
                    CLLocationCoordinate2D coordinate =CLLocationCoordinate2DMake([object[@"latitude"] doubleValue], [object[@"longitude"] doubleValue]);
                    CustomMKPointAnnotation *pin = [[CustomMKPointAnnotation alloc] init];
                    pin.coordinate = coordinate;
                    pin.title = object[@"name"];
                    pin.subtitle = object[@"category"];
                    pin.lifetstyleObject = life;
                    pin.needAnimation = NO;
                    [coors addObject:pin];
                }
            }
            
            //save
            [[SharedDataManager sharedInstance] saveContext];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mapView addAnnotations:coors];
            });
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];
}

#pragma mar - all method table view needs

-(void)fetchLocalDataForListWithRadius:(NSNumber *)radius categoryType:(DDCategoryType)categoryType{

    self.tableViewDataSource = nil;
    self.tableViewDataSource = [NSMutableArray array];
    
    NSDictionary *dictionary = [Helper userLocation];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:radius];
    
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithRegion:region
                                                            categoryType:self.categoryType];
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count > 0) {
        [self.tableViewDataSource addObjectsFromArray:fetchedObjects];
        [self.tableView reloadData];
        [((UIRefreshControl *)[self.tableView viewWithTag:kRefreshControlTag]) endRefreshing];
    }
}

-(void)fetchServerDataForListAroundCenter:(CLLocationCoordinate2D)center
                                   raidus:(NSNumber *)radius
                             categoryType:(DDCategoryType)categoryType{
    
    if (self.pfQuery) {
        [self.pfQuery cancel];
        self.pfQuery = nil;
    }
    
    __block LifestyleDetailVC *weakSelf = self;
    
    NSString *parseClassName = [LifestyleCategory getParseClassNameForCategoryType:self.categoryType];
    if (!parseClassName) {
        return;
    }
    self.pfQuery = [[PFQuery alloc] initWithClassName:parseClassName];
    //latest post goes to the top.
    

    if (categoryType != DDCategoryTypeJob) {
        [self.pfQuery addBoundingCoordinatesToCenter:center radius:radius];
        [self.pfQuery orderByAscending:@"name"];
    }
    if (categoryType == DDCategoryTypeJob || categoryType == DDCategoryTypeTradeAndSell) {
        [self.pfQuery orderByDescending:@"createdAt"];
        [self.pfQuery whereKey:DDObjectIdKey
                notContainedIn:[Helper flaggedLifeStyleObjectIds]];
    }

    [self.pfQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error && objects>0) {
            
            if (weakSelf.tableViewDataSource) {

                weakSelf.tableViewDataSource = nil;
            }
            weakSelf.tableViewDataSource = [NSMutableArray array];

            //construct array of indexPath and store parse data to local
            for (PFObject *parseObject in objects) {

                LifestyleObject *life;
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.objectId MATCHES[cd] %@",parseObject.objectId];
                NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"LifestyleObject"];
                request.predicate = predicate;
                NSArray *array = [[[SharedDataManager sharedInstance] managedObjectContext] executeFetchRequest:request error:nil];
                if (array.count == 1) {
                    life = array[0];
                    if ([life.updatedAt compare:parseObject.updatedAt] == NSOrderedAscending) {
                        [life populateFromObject:parseObject];
                    }
                    
                }else{
                    life = [NSEntityDescription insertNewObjectForEntityForName:@"LifestyleObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [life populateFromObject:parseObject];
                }
                
                
                if ([parseObject[DDIsBadContentKey] boolValue]) {
                    continue;
                }
                
                [[SharedDataManager sharedInstance] saveContext];
                [weakSelf.tableViewDataSource addObject:life];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
                [((UIRefreshControl *)[self.tableView viewWithTag:kRefreshControlTag]) endRefreshing];
            });
        }
    }];
}

-(void)handleDataDisplayPeripheral:(double)newValue{
    NSString *label = IS_RESTAURANT ? @"Restaurant" : (IS_MARKET ? @"Supermarket" : @"Trade and Sell");
    
    [[GAnalyticsManager shareManager] trackUIAction:@"change display radius" label:label value:@(newValue)];
    [Flurry logEvent:[NSString stringWithFormat:@"%@ change display radius", label] withParameters:@{@"radius":@(newValue)}];
    if (![Reachability canReachInternet]) {
        [self fetchLocalDataForListWithRadius:[NSNumber numberWithDouble:newValue] categoryType:self.categoryType];
    } else {
        NSDictionary *userLocation = [Helper userLocation];
        CLLocationCoordinate2D coor = CLLocationCoordinate2DMake([userLocation[@"latitude"] doubleValue], [userLocation[@"longitude"] doubleValue]);
        [self fetchServerDataForListAroundCenter:coor
                                          raidus:[NSNumber numberWithDouble:newValue]
                                    categoryType:self.categoryType];
    }
}

#pragma mark -- Location manager

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //the most recent location update is at the end of the array.
    CLLocation *location = (CLLocation *)[locations lastObject];
    
    //-didUpdateLocations gets called very frequently. dont fetch server until there is significant location update
    if (previousLocation) {
        CLLocationDistance distance = [location distanceFromLocation:previousLocation];
        if(distance/1609 < kLocationNotifyThreshold){
            return;
        }
    }
    previousLocation = location;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:location.coordinate.latitude],@"latitude",[NSNumber numberWithDouble:location.coordinate.longitude],@"longitude", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //job and trade doesnt require location information
    if (IS_RES_MARKT && (self.tableViewDataSource == nil || self.tableViewDataSource.count == 0)) {
        NSNumber *rememberedRadius = IS_RESTAURANT ? [self restaurantDataRadius] : [self supermarketDataRadius];
        [self fetchServerDataForListAroundCenter:location.coordinate
                                          raidus:rememberedRadius
                                    categoryType:self.categoryType];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");

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

#pragma mark - table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.tableViewDataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LifestyleObject *object = self.tableViewDataSource[indexPath.row];

    if (IS_RES_MARKT) {
        NameAddressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNameAndAddressCellReuseID forIndexPath:indexPath];
        cell.nameLabel.text = object.name;
        cell.addressLabel.text = object.address;
        cell.isVerified = NO;
        cell.isAuthetic = NO;
        
        return cell;
    }else{
        JobTradeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJobAndTradeCellReuseID forIndexPath:indexPath];
        cell.delegate = self;
        cell.contentTextView.text = nil;
        cell.contentTextView.text = object.content;
        cell.flagButton.enabled = !object.isBadContent.boolValue;
        
        return cell;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section==0 && !(IS_JOB)) {
        return self.headerView;
    }else{
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section==0 && !(IS_JOB)) {
        return 40.0f;
    } else {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LifestyleObject *object = self.tableViewDataSource[indexPath.row];
    
    if (IS_RES_MARKT) {
        
        return [NameAddressTableViewCell heightForCellWithName:object.name address:object.address cellWidth:tableView.frame.size.width];
    } else {
        LifestyleObject *object = self.tableViewDataSource[indexPath.row];
        
        return [JobTradeTableViewCell heightForCellWithContentString:object.content cellWidth:CGRectGetWidth(tableView.frame)];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[NameAddressTableViewCell class]]) {
        [self performSegueWithIdentifier:kToObjectDetailVCSegueID sender:cell];
    }
}

#pragma mark - map delegate

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered{
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    self.reResearchButton.hidden = NO;
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    // Only zoom if it's the first time locating the user
    if (!self.isMapLoaded) {
        
        [mapView setCenterCoordinate:userLocation.coordinate animated:NO];
        MKCoordinateRegion region = mapView.region;
        region.center = userLocation.coordinate;
        //show an area whose north to south distance is 1.5 miles and west to east 1 mile
        static CLLocationDegrees latitudeDelta = 1.5/MILE_PER_DELTA;
        static CLLocationDegrees longitudeDelta = 1/MILE_PER_DELTA;
        region.span = MKCoordinateSpanMake(latitudeDelta,longitudeDelta);
        [mapView setRegion:region animated:NO];
        
        [UIView animateWithDuration:.3 animations:^{
        } completion:^(BOOL finished) {
            [self fetchLocalDataWithRegion:mapView.region];
            [self fetchServerDataWithRegion:mapView.region];
        }];
        self.isMapLoaded = YES;
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");
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

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }else{
        static NSString *identifier = @"view";
        MKPinAnnotationView *view = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (!view) {
            view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            CustomMKPointAnnotation *an = (CustomMKPointAnnotation *)annotation;
            view.animatesDrop = an.needAnimation;
            view.canShowCallout = YES;
            view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        return view;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    CustomMKPointAnnotation *annotation = (CustomMKPointAnnotation *)view.annotation;
    lifestyleToPass = annotation.lifetstyleObject;
    //push to detail
    [self performSegueWithIdentifier:kToObjectDetailVCSegueID sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:kToObjectDetailVCSegueID]){
        
        LifestyleObjectDetailTableVC *vc = (LifestyleObjectDetailTableVC *)segue.destinationViewController;
        
        // from tb view or from map
        
        if ([sender isKindOfClass:[NameAddressTableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            vc.lifestyleObject = self.tableViewDataSource[indexPath.row];
        } else {
            vc.lifestyleObject = lifestyleToPass;
        }
    }
}

#pragma mark - JobTradeTableViewCellDelegate

- (void)flagBadContentButtonTappedOnCell:(JobTradeTableViewCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __block LifestyleObject *lifeObject = self.tableViewDataSource[indexPath.row];
    
    [self showReportAlertWithBlock:^(BOOL yesButtonTapped) {
        if (yesButtonTapped) {
            [Helper createAuditWithObjectId:lifeObject.objectId category:lifeObject.category];
            [Helper flagLifeStyleObject:lifeObject];
            
            lifeObject.isBadContentLocal = @YES;
            [[SharedDataManager sharedInstance] saveContext];
            
            [self.tableViewDataSource removeObject:lifeObject];
            [self.tableView reloadData];
        }
    }];
}

@end
