//
//  LifestyleDetailViewController.m
//  CIU
//
//  Created by Huang, Sihang on 8/22/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleDetailViewController.h"
#import "Query.h"
#import "SharedDataManager.h"
#import <CoreLocation/CoreLocation.h>
#import "NSString+Map.h"
#import <Parse/Parse.h>
#import "NSPredicate+Utilities.h"
#import "LifestyleObject.h"
#import "LifestyleObject+Utilities.h"
#import "CustomMKPointAnnotation.h"
#import "LifestyleObjectDetailTableViewController.h"
#import "PFQuery+Utilities.h"
#import "Reachability.h"
#import "Helper.h"
#import "ComposeViewController.h"
#import "LoadingTableViewCell.h"
#import "GenericTableViewCell.h"
#import "JobTradeTableViewCell.h"
#import "DisplayPeripheralHeaderView.h"
#import "UIColor+CIUColors.h"

#define MILE_PER_DELTA 69.0
#define IS_JOB_TRADE [self.categoryName isEqualToString:@"Jobs"] || [self.categoryName isEqualToString:@"Trade and Sell"]
#define IS_JOB [self.categoryName isEqualToString:@"Jobs"]
#define IS_TRADE [self.categoryName isEqualToString:@"Trade and Sell"]
#define IS_RES_MARKT [self.categoryName isEqualToString:@"Restaurant"] || [self.categoryName isEqualToString:@"Supermarket"]
#define IS_RESTAURANT [self.categoryName isEqualToString:@"Restaurant"]
#define IS_MARKET [self.categoryName isEqualToString:@"Supermarket"]

NSInteger const kRefreshControlTag = 31;

static const CGFloat kLocationNotifyThreshold = 1.0;
static NSString *const kSupermarketDataRadiusKey = @"kSupermarketDataRadius";
static NSString *const kRestaurantDataRadiusKey = @"kRestaurantDataRadiusKey";

static NSInteger const kJobDisclaimerAlertTag = 50;
static NSInteger const kTradeDisclaimerAlertTag = 51;
static NSString *const kJobDisclaimerKey = @"kJobDisclaimerKey";
static NSString *const kTradeDisclaimerKey = @"kTradeDisclaimerKey";

@interface LifestyleDetailViewController()<LoadingTableViewCellDelegate,CLLocationManagerDelegate,MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate, JobTradeTableViewCellDelegate>{
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

@implementation LifestyleDetailViewController

- (NSNumber *)restaurantDataRadius
{
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kRestaurantDataRadiusKey];
    if (!radius) {
        [self setRestaurantDataRadius:@5];
        return @5;
    } else {
        return radius;
    }
}

- (void)setRestaurantDataRadius:(NSNumber *)newRadius
{
    [[NSUserDefaults standardUserDefaults] setObject:newRadius forKey:kRestaurantDataRadiusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)supermarketDataRadius
{
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kSupermarketDataRadiusKey];
    if (!radius) {
        [self setSupermarketDataRadius:@5];
        return @5;
    } else {
        return radius;
    }
}

- (void)setSupermarketDataRadius:(NSNumber *)newRadius
{
    [[NSUserDefaults standardUserDefaults] setObject:newRadius forKey:kSupermarketDataRadiusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (DisplayPeripheralHeaderView *)headerView
{
    if (!_headerView) {
        NSNumber *radius = IS_RESTAURANT ? [self restaurantDataRadius] : [self supermarketDataRadius];
        _headerView = [[DisplayPeripheralHeaderView alloc] initWithCurrentValue:radius stepValue:@(5.0) minimunValue:@(5.0) maximunValue:@(30.0) actionBlock:^(double newValue) {
            
            if (IS_RESTAURANT) {
                [self setRestaurantDataRadius:@(newValue)];
            } else {
                [self setSupermarketDataRadius:@(newValue)];
            }
            [self handleDataDisplayPeripheral:newValue];
        }];
    }
    
    return _headerView;
}

-(UIButton *)reResearchButton
{
    if (!_reResearchButton) {
        _reResearchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_reResearchButton setTitle:@"Redo search in this area" forState:UIControlStateNormal];
        [_reResearchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _reResearchButton.titleLabel.font = [UIFont systemFontOfSize:18.0];
        _reResearchButton.hidden = YES;
        _reResearchButton.backgroundColor = [UIColor themeGreen];
        [_reResearchButton addTarget:self action:@selector(reSearchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_mapView addSubview:_reResearchButton];
        _reResearchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_mapView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_reResearchButton]-0-|"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_reResearchButton)]];
        [_mapView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_reResearchButton(44)]-0-|"
                                                                         options:kNilOptions
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(_reResearchButton)]];
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
    
    // Note: empty back button title is set in IB. Select navigation bar in LifestyleTableViewController. The tilte is set to an empty string.
    
    isOffline = ![Reachability canReachInternet];

    if (IS_RES_MARKT) {
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"List",@"Map"]];
        [self.segmentedControl addTarget:self
                             action:@selector(segmentedControlTapped:)
                   forControlEvents:UIControlEventValueChanged];
        self.segmentedControl.selectedSegmentIndex = 0;
        self.navigationItem.titleView = self.segmentedControl;
        
        [[GAnalyticsManager shareManager] trackScreen:IS_RESTAURANT ? @"Restaurant" : @"SuperMarket"];
        
    }else if (IS_JOB_TRADE) {
        
        if (IS_JOB) {
            self.title = @"Jobs";
            if (![[NSUserDefaults standardUserDefaults] objectForKey:kJobDisclaimerKey]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"亲，这里需要您理解并同意，DaDa哒哒仅为信息发布平台，并非实际招聘公司或企业，如您因参与招聘活动而产生任何人身损害及/或财物损失，我们无法承担任何责任喔！" delegate:self cancelButtonTitle:nil otherButtonTitles:@"同意并接受", nil];
                alert.tag = kJobDisclaimerAlertTag;
                [alert show];
            }
        } else {
            if (![[NSUserDefaults standardUserDefaults] objectForKey:kTradeDisclaimerKey]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"亲，这里需要理解并同意，DaDa哒哒仅为信息发布平台，并非买卖或交易中的任何一方，如您因在卖货或交易活动而产生任何人身损害及/或财物损失，我们对此不承担任何责任。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"同意并接受", nil];
                alert.tag = kTradeDisclaimerAlertTag;
                [alert show];
            }
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
        [self fetchLocalDataForListWithRadius:rememberedRadius];
        
    }else{
        if (IS_JOB_TRADE) {
            //jobs, trade and sell don't need location info yet
            [self fetchServerDataForListAroundCenter:CLLocationCoordinate2DMake(0, 0) raidus:rememberedRadius];
            
        }else if (IS_RES_MARKT) {
            self.locationManager = [Helper initLocationManagerWithDelegate:self];
            
            //this is becuase we requested for authorization in GenericTableViewController already. may need work to improve this flow
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
                
                NSDictionary *userLocation = [Helper userLocation];
                CLLocationCoordinate2D coor = CLLocationCoordinate2DMake([userLocation[@"latitude"] doubleValue], [userLocation[@"longitude"] doubleValue]);
                [self fetchServerDataForListAroundCenter:coor raidus:rememberedRadius];
            }
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
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
    ComposeViewController *compose = (ComposeViewController *)vc.topViewController;
    compose.categoryName = self.categoryName;
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
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LifestyleObject"];
    // Predicate
    NSPredicate *excludeBadContent = [NSPredicate predicateWithFormat:@"self.isBadContent == %@", @NO];
    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@",[Helper getParseClassNameForCategoryName:self.categoryName]];
    if (IS_RES_MARKT) {
        NSPredicate *geoLocation = [NSPredicate boudingCoordinatesPredicateForRegion:region];
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludeBadContent, geoLocation, categoryPredicate]];
    } else {
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludeBadContent, categoryPredicate]];
    }
    // Sort descriptor
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    return fetchRequest;
}

-(void)fetchLocalDataWithRegion:(MKCoordinateRegion)region{
    
    self.mapViewDataSource = nil;
    self.mapViewDataSource = [NSMutableArray array];
    
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithRegion:region];
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
    
    NSString *parseClassName = [Helper getParseClassNameForCategoryName:self.categoryName];
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

-(void)fetchLocalDataForListWithRadius:(NSNumber *)radius{

    self.tableViewDataSource = nil;
    self.tableViewDataSource = [NSMutableArray array];
    
    NSDictionary *dictionary = [Helper userLocation];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:radius];
    
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithRegion:region];
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if (fetchedObjects.count > 0) {
        [self.tableViewDataSource addObjectsFromArray:fetchedObjects];
        [self.tableView reloadData];
        [((UIRefreshControl *)[self.tableView viewWithTag:kRefreshControlTag]) endRefreshing];
    }
}

-(void)fetchServerDataForListAroundCenter:(CLLocationCoordinate2D)center raidus:(NSNumber *)radius{
    
    if (self.pfQuery) {
        [self.pfQuery cancel];
        self.pfQuery = nil;
    }
    
    __block LifestyleDetailViewController *weakSelf = self;
    
    NSString *parseClassName = [Helper getParseClassNameForCategoryName:self.categoryName];
    if (!parseClassName) {
        return;
    }
    self.pfQuery = [[PFQuery alloc] initWithClassName:parseClassName];
    //latest post goes to the top.
    

    if (IS_RES_MARKT) {
        [self.pfQuery addBoundingCoordinatesToCenter:center radius:radius];
        [self.pfQuery orderByAscending:@"name"];
    } else{
        [self.pfQuery whereKey:@"isBadContent" notEqualTo:@YES];
        [self.pfQuery orderByDescending:@"createdAt"];
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
    [[GAnalyticsManager shareManager] trackUIAction:@"change display radius" label:IS_RESTAURANT ? @"Restaurant" : @"Supermarket" value:@(newValue)];
    [Flurry logEvent:[NSString stringWithFormat:@"%@ change display radius",IS_RESTAURANT ? @"Restaurant" : @"Supermarket"] withParameters:@{@"radius":@(newValue)}];
    if (![Reachability canReachInternet]) {
        [self fetchLocalDataForListWithRadius:[NSNumber numberWithDouble:newValue]];
    } else {
        NSDictionary *userLocation = [Helper userLocation];
        CLLocationCoordinate2D coor = CLLocationCoordinate2DMake([userLocation[@"latitude"] doubleValue], [userLocation[@"longitude"] doubleValue]);
        [self fetchServerDataForListAroundCenter:coor raidus:[NSNumber numberWithDouble:newValue]];
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
        [self fetchServerDataForListAroundCenter:location.coordinate raidus:rememberedRadius];
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
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kLocationServiceDisabledAlertTitle message:kLocationServiceDisabledAlertMessage delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
//                [alert show];

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
    static NSString *regularCell = @"cell";
    static NSString *jobAndTradeCell = @"cellJob";

    if (IS_RES_MARKT) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:regularCell forIndexPath:indexPath];
        cell.textLabel.text = object.name;
        cell.detailTextLabel.text = object.address;
        return cell;
    }else{
        JobTradeTableViewCell *cell = (JobTradeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:jobAndTradeCell forIndexPath:indexPath];
        cell.delegate = self;
        cell.contentLabel.text = object.content;
        cell.contentLabel.font = [UIFont systemFontOfSize:14.0f];
        
        if (object.isBadContent.boolValue) {
            cell.flagButton.enabled = NO;
        } else {
            cell.flagButton.enabled = YES;
        }
        
        return cell;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section==0 && IS_RES_MARKT) {
        return self.headerView;
    }else{
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section==0 && IS_RES_MARKT) {
        return 40.0f;
    } else {
        return 0;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (IS_RES_MARKT) {
        return 44;
    } else {
        LifestyleObject *object = self.tableViewDataSource[indexPath.row];
        NSString *content = object.content;
        CGRect rect = [content boundingRectWithSize:CGSizeMake(280, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]} context:NULL];
        
        //40 takes the flag button into consideration. 10 spacing and 30 button height
        if (rect.size.height + 40 <44.0f) {
            return 44.0f;
        } else {
            //5.0f is becuase the top margin is 5 pixels
            return rect.size.height + 40 +5.0f;
        }
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
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kLocationServiceDisabledAlertTitle message:kLocationServiceDisabledAlertMessage delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
//                [alert show];
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
    [self performSegueWithIdentifier:@"toObjectDetail" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"toObjectDetail"]) {
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
            LifestyleObject *life = self.tableViewDataSource[indexPath.row];
            lifestyleToPass = life;
        }
        LifestyleObjectDetailTableViewController *vc = (LifestyleObjectDetailTableViewController *)segue.destinationViewController;
        vc.lifestyleObject = lifestyleToPass;
    }
}

#pragma mark - JobTradeTableViewCellDelegate

- (void)flagBadContentButtonTappedOnCell:(JobTradeTableViewCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __block LifestyleObject *lifeObject = self.tableViewDataSource[indexPath.row];
    
    cell.flagButton.enabled = NO;
    
    [self flagObjectForId:lifeObject.objectId parseClassName:[Helper getParseClassNameForCategoryName:self.categoryName] completion:^(BOOL succeeded, NSError *error) {
        lifeObject.isBadContent = @YES;
        [[SharedDataManager sharedInstance] saveContext];
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kJobDisclaimerAlertTag) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kJobDisclaimerKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (alertView.tag == kTradeDisclaimerAlertTag) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kTradeDisclaimerKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}
@end
