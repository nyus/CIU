//
//  RestaurantVC.m
//  DaDa
//
//  Created by Sihang on 9/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <Parse/Parse.h>
#import <Masonry/Masonry.h>
#import "RestaurantVC.h"
#import "DisplayPeripheralHeaderView.h"
#import "Helper.h"
#import "NameAddressTableViewCell.h"
#import "LifestyleObject.h"
#import "LifestyleObject+Utilities.h"
#import "LifestyleObjectDetailTableVC.h"
#import "PFQuery+Utilities.h"

static float const kServerFetchCount = 10;
static float const kLocalFetchCount = 50;
static UIImage *defaultAvatar;
static NSString *const kEntityName = @"LifestyleObject";
static NSString *const kRestaurantDataRadiusKey = @"kRestaurantDataRadiusKey";
static NSString *const kNameAndAddressCellReuseID = @"kNameAndAddressCellReuseID";
static NSString *const kToObjectDetailVCSegueID = @"toObjectDetail";

@interface RestaurantVC ()

@property (nonatomic, strong) DisplayPeripheralHeaderView *headerView;
@property (nonatomic, strong) UIButton *redoResearchButton;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation RestaurantVC

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

- (DisplayPeripheralHeaderView *)headerView
{
    if (!_headerView) {
        NSNumber *radius = [self restaurantDataRadius];
        _headerView = [[DisplayPeripheralHeaderView alloc] initWithCurrentValue:radius
                                                                      stepValue:@(5.0)
                                                                   minimunValue:@(5.0)
                                                                   maximunValue:@(30.0)
                                                                    contentMode:ContentModeLeft
                                                                    actionBlock:^(double newValue) {
                                                                        [self setRestaurantDataRadius:@(newValue)];
                                                                        [self handleDataDisplayPeripheral];
                                                                        
                                                                        NSString *label = @"Restaurant";
                                                                        [[GAnalyticsManager shareManager] trackUIAction:@"change display radius" label:label value:@(newValue)];
                                                                        [Flurry logEvent:[NSString stringWithFormat:@"%@ change display radius", label] withParameters:@{@"radius":@(newValue)}];
                                                                    }];
    }
    
    return _headerView;
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem.accessibilityLabel = @"Back";
    [self.tableView registerClass:[NameAddressTableViewCell class] forCellReuseIdentifier:kNameAndAddressCellReuseID];
    
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
                               fetchRadius:[[self restaurantDataRadius] floatValue]
                          greaterOrEqualTo:nil
                           lesserOrEqualTo:nil
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius]]];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[PFUser currentUser] fetchInBackground];
    [Flurry logEvent:@"View restaurant" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    self.mapView.showsUserLocation = NO;
    [self.fetchQuery cancel];
    [Flurry endTimedEvent:@"View restaurant" withParameters:nil];
}

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


#pragma mark - Action

- (void)handleRedoSearchButtonTapped
{
    [[GAnalyticsManager shareManager] trackUIAction:@"buttonPress" label:@"Restaurant-Redo search in map" value:nil];
    [Flurry logEvent:@"Restaurant-Redo search in map"];
    
#warning
    if (self.isInternetPresentOnLaunch) {
//        [self fetchServerDataWithRegion:self.mapView.region];
    } else {
//        [self fetchLocalDataWithRegion:self.mapView.region];
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
                               fetchRadius:[[self restaurantDataRadius] floatValue]
                          greaterOrEqualTo:nil
                           lesserOrEqualTo:nil
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
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
                                                  label:@"Restaurant-list"
                                                  value:nil];
        [Flurry logEvent:@"Switch to list view"
          withParameters:@{@"screen":@"Restaurant"}];
    }else{
        
        //map view
        self.mapView.showsUserLocation = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            self.tableView.alpha = 0.0f;
            self.mapView.alpha = 1.0f;
        }];
        
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect"
                                                  label:@"Restaurant-map"
                                                  value:nil];
        [Flurry logEvent:@"Switch to map view"
          withParameters:@{@"screen":@"Restaurant"}];
    }
}

#pragma mark - MapView data

#pragma mark - Override

- (NSString *)serverDataParseClassName
{
    return DDRestaurantParseClassName;
}

- (NSString *)localDataEntityName
{
    return kEntityName;
}

- (float)dataFetchRadius
{
    return [self restaurantDataRadius].floatValue;;
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
                                lesserOrEqualTo:self.leastObjectDate];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                               fetchRadius:[[self restaurantDataRadius] floatValue]
                          greaterOrEqualTo:nil
                           lesserOrEqualTo:self.leastObjectDate
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius]]];
    }
}

- (void)setupServerQueryWithClassName:(NSString *)className
                           fetchLimit:(NSUInteger)fetchLimit
                          fetchRadius:(CGFloat)fetchRadius
                     greaterOrEqualTo:(NSDate *)greaterDate
                      lesserOrEqualTo:(NSDate *)lesserDate
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
    
    if (greaterDate) {
        [self.fetchQuery whereKey:DDCreatedAtKey
                      greaterThan:greaterDate];
    }
    
    if (lesserDate) {
        [self.fetchQuery whereKey:DDCreatedAtKey
                         lessThan:lesserDate];
    }
    
    self.fetchQuery.limit = fetchLimit;
}

- (void)populateManagedObject:(NSManagedObject *)managedObject
              fromParseObject:(PFObject *)object
{
    [((LifestyleObject *)managedObject) populateFromParseObject:object];
}

#pragma mark - table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataSource.count;
}

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[NameAddressTableViewCell class]]) {
        [self performSegueWithIdentifier:kToObjectDetailVCSegueID sender:cell];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:kToObjectDetailVCSegueID]){
        
        LifestyleObjectDetailTableVC *vc = (LifestyleObjectDetailTableVC *)segue.destinationViewController;
        
        // from tb view or from map
        
        if ([sender isKindOfClass:[NameAddressTableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            vc.lifestyleObject = self.dataSource[indexPath.row];
        }
    }
}

@end
