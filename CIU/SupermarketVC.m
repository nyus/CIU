//
//  SupermarketVC.m
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "SupermarketVC.h"
#import "DisplayPeripheralHeaderView.h"
#import "NameAddressTableViewCell.h"
#import "PFQuery+Utilities.h"
#import "LifestyleObject.h"
#import "LifestyleObject+Utilities.h"
#import "NSPredicate+Utilities.h"
#import "Helper.h"
static NSString *const kNameAndAddressCellReuseID = @"kNameAndAddressCellReuseID";

static CGFloat const kServerFetchCount = 50.0;
static CGFloat const kLocalFetchCount = 50.0;
static NSString *const kSupermarketDataRadiusKey = @"kSupermarketDataRadiusKey";
static NSString *const kEntityName = @"LifestyleObject";
static NSString *const kCategoryName = @"Supermarket";

@interface SupermarketVC ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation SupermarketVC

- (NSNumber *)supermarkerDataRadius
{
    NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kSupermarketDataRadiusKey];
    
    if (!radius) {
        [self setSupermarkerDataRadius:@5];
        
        return @5;
    } else {
        return radius;
    }
}

- (void)setSupermarkerDataRadius:(NSNumber *)newRadius
{
    [[NSUserDefaults standardUserDefaults] setObject:newRadius forKey:kSupermarketDataRadiusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (DisplayPeripheralHeaderView *)headerView
{
    if (!_headerView) {
        NSNumber *radius = [self supermarkerDataRadius];
        _headerView = [[DisplayPeripheralHeaderView alloc] initWithCurrentValue:radius
                                                                      stepValue:@(5.0)
                                                                   minimunValue:@(5.0)
                                                                   maximunValue:@(30.0)
                                                                    contentMode:ContentModeLeft
                                                                    actionBlock:^(double newValue) {
                                                                        
                                                                        self.greaterValue = nil;
                                                                        self.lesserValue = nil;
                                                                        
                                                                        [self setSupermarkerDataRadius:@(newValue)];
                                                                        [self handleDataDisplayPeripheral];
                                                                        
                                                                        NSString *label = @"Supermarker";
                                                                        [[GAnalyticsManager shareManager] trackUIAction:@"change display radius" label:label value:@(newValue)];
                                                                        [Flurry logEvent:[NSString stringWithFormat:@"%@ change display radius", label] withParameters:@{@"radius":@(newValue)}];
                                                                    }];
    }
    
    return _headerView;
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Supermarker";
    self.navigationItem.leftBarButtonItem.accessibilityLabel = @"Back";
    
    [self setUpSegmentedControl];
    [self addInfiniteRefreshControl];
    
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:nil];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self supermarkerCategoryPredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius]]];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[PFUser currentUser] fetchInBackground];
    [Flurry logEvent:@"View supermarker" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    self.mapView.showsUserLocation = NO;
    [self.fetchQuery cancel];
    [Flurry endTimedEvent:@"View supermarker" withParameters:nil];
}

#pragma mark - View Setup

- (void)setUpSegmentedControl
{
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"List",@"Map"]];
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlTapped:)
                    forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.accessibilityLabel = kListMapSegmentedControlAccessibilityLabel;
    
    self.navigationItem.titleView = self.segmentedControl;
}

#pragma mark - Helper

- (NSPredicate *)supermarkerCategoryPredicate
{
    return [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@", kCategoryName];
}


#pragma mark - Action

- (void)handleRedoSearchButtonTapped
{
    [[GAnalyticsManager shareManager] trackUIAction:@"buttonPress" label:@"Supermarker-Redo search in map" value:nil];
    [Flurry logEvent:@"Supermarker-Redo search in map"];
    
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithRegion:self.mapView.region];
    } else {
        [self fetchLocalDataWithRegion:self.mapView.region];
    }
}

-(void)handleDataDisplayPeripheral{
    
    [self.dataSource removeAllObjects];
    [self.tableView reloadData];
    
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:nil];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self supermarkerCategoryPredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius]]];
    }
}

-(void)segmentedControlTapped:(UISegmentedControl *)sender{
    
    //list view
    if (sender.selectedSegmentIndex==0) {
        [UIView animateWithDuration:.3 animations:^{
            self.tableView.alpha = 1.0f;
            self.mapView.alpha = 0.0f;
        }];
        
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect"
                                                  label:@"Supermarker-list"
                                                  value:nil];
        [Flurry logEvent:@"Switch to list view"
          withParameters:@{@"screen":@"Supermarker"}];
    }else{
        
        //map view
        self.mapView.showsUserLocation = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            self.tableView.alpha = 0.0f;
            self.mapView.alpha = 1.0f;
        }];
        
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect"
                                                  label:@"Supermarker-map"
                                                  value:nil];
        [Flurry logEvent:@"Switch to map view"
          withParameters:@{@"screen":@"Supermarker"}];
    }
}

#pragma mark - Override

- (NSString *)serverDataParseClassName
{
    return DDSupermarketParseClassName;
}

- (NSString *)localDataEntityName
{
    return kEntityName;
}

- (float)dataFetchRadius
{
    return [self supermarkerDataRadius].floatValue;;
}

- (float)serverFetchCount
{
    return kServerFetchCount;
}

- (float)localFetchCount
{
    return kLocalFetchCount;
}

- (NSString *)keyForLocalDataSortDescriptor
{
    return DDNameKey;
}

- (BOOL)orderLocalDataInAscending
{
    return YES;
}

- (void)handleInfiniteScroll
{
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:self.lesserValue];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self supermarkerCategoryPredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius]]];
    }
}

- (id)valueToCompareAgainst:(id)object
{
    id valueToCompare;
    
    if ([object isKindOfClass:[PFObject class]]) {
        valueToCompare = [((PFObject *)object) objectForKey:@"name"];
    } else if ([object isKindOfClass:[NSManagedObject class]]) {
        valueToCompare = [object name];
    }
    
    return valueToCompare;
}

- (NSFetchRequest *)localDataFetchRequestWithEntityName:(NSString *)entityName
                                             fetchLimit:(NSUInteger)fetchLimit
                                             predicates:(NSArray *)predicates
{
    NSFetchRequest *fetchRequest = [super localDataFetchRequestWithEntityName:entityName
                                                                   fetchLimit:fetchLimit
                                                                   predicates:predicates];
    
    fetchRequest.fetchOffset = self.dataSource.count;
    
    return fetchRequest;
}

- (void)setupServerQueryWithClassName:(NSString *)className
                           fetchLimit:(NSUInteger)fetchLimit
                          fetchRadius:(CGFloat)fetchRadius
                     greaterOrEqualTo:(id)greaterValue
                      lesserOrEqualTo:(id)lesserValue
{
    if (self.fetchQuery) {
        [self.fetchQuery cancel];
        self.fetchQuery = nil;
    }
    
    NSDictionary *dictionary = [Helper userLocation];
    if (!dictionary) {
        
        return;
    }
    
    self.fetchQuery = [[PFQuery alloc] initWithClassName:className];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[DDLatitudeKey] doubleValue],
                                                               [dictionary[DDLongitudeKey] doubleValue]);
    [self.fetchQuery addBoundingCoordinatesToCenter:center radius:@(fetchRadius)];
    [self.fetchQuery orderByAscending:DDNameKey];
    [self.fetchQuery whereKey:DDObjectIdKey
               notContainedIn:[Helper flaggedLifeStyleObjectIds]];
    
    // Make sure all the results are consecutive. greaterValue and lesserValue cannot be name and the results are ordered by name
    
    self.fetchQuery.skip = self.dataSource.count;
    self.fetchQuery.limit = fetchLimit;
}

- (void)populateManagedObject:(NSManagedObject *)managedObject
              fromParseObject:(PFObject *)object
{
    [((LifestyleObject *)managedObject) populateFromParseObject:object];
}

#pragma mark - Mapview Delegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LifestyleObject *object = self.dataSource[indexPath.row];
    
    NameAddressTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNameAndAddressCellReuseID forIndexPath:indexPath];
    cell.nameLabel.text = object.name;
    cell.addressLabel.text = object.address;
    cell.isVerified = NO;
    cell.isAuthetic = NO;
    
    return cell;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    return self.headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 40.0f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LifestyleObject *object = self.dataSource[indexPath.row];
    
    return [NameAddressTableViewCell heightForCellWithName:object.name
                                                   address:object.address
                                                 cellWidth:tableView.frame.size.width];
}

@end
