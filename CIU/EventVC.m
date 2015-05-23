//
//  EventTableViewController.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "EventVC.h"
#import "Event.h"
#import "Event+Utilities.h"
#import "EventTableViewCell.h"
#import "PFQuery+Utilities.h"
#import "NSPredicate+Utilities.h"
#import "Helper.h"
#import "SVPullToRefresh.h"
#import "DisplayPeripheralHeaderView.h"

static float const kServerFetchCount = 50;
static float const kLocalFetchCount = 20;
static NSInteger const kEventDisclaimerAlertTag = 50;
static NSString *managedObjectName = @"Event";
static NSString *const kEventDataRadiusKey = @"kEventDataRadiusKey";
static NSString *const kEventDisclaimerKey = @"kEventDisclaimerKey";
static NSString *const kLastFetchDateKey = @"lastFetchEventDate";

@interface EventVC()<UITableViewDataSource,UITableViewDelegate, EventTableViewCellDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DisplayPeripheralHeaderView *headerView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong, readwrite) NSNumber *eventRadius;

@end

@implementation EventVC{
    NSNumber *_eventRadius;
}

- (NSNumber *)eventRadius{
    if (!_eventRadius) {
        NSNumber *radius = [[NSUserDefaults standardUserDefaults] objectForKey:kEventDataRadiusKey];
        if (!radius) {
            _eventRadius = @30;
        } else {
            _eventRadius = radius;
        }
    }
    return _eventRadius;
}

- (void)setEventRadius:(NSNumber *)eventRadius{
    if (![_eventRadius isEqual:eventRadius]) {
        [[NSUserDefaults standardUserDefaults] setObject:eventRadius forKey:kEventDataRadiusKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _eventRadius = eventRadius;
    }
}

- (DisplayPeripheralHeaderView *)headerView
{
    if (!_headerView) {
        _headerView = [[DisplayPeripheralHeaderView alloc] initWithCurrentValue:[self eventRadius]
                                                                      stepValue:@10
                                                                   minimunValue:@10
                                                                   maximunValue:@50
                                                                    contentMode:ContentModeCenter
                                                                    actionBlock:^(double newValue) {
            
            [[GAnalyticsManager shareManager] trackUIAction:@"event - change display radius" label:@"event" value:@(newValue)];
            [Flurry logEvent:@"event - change display radius" withParameters:@{@"radius":@(newValue)}];
            [self setEventRadius:@(newValue)];
            [self handleDataDisplayPeripheral];
        }];
    }
    
    return _headerView;
}

-(void)handleDataDisplayPeripheral{
    
    // Reset
    _localDataCount = 0;
    _serverDataCount = 0;
    
    self.dataSource = nil;
    [self.tableView reloadData];
    if (INTERNET_AVAILABLE) {
        [self pullDataFromServerWithMemorizedLocation];
    } else {
        [self pullDataFromLocal];
    }
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[GAnalyticsManager shareManager] trackScreen:@"Event"];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kEventDisclaimerKey]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"亲，请您务必理解并同意，DaDa哒哒仅为信息发布平台，并非活动的主办方或发起人，如您因在参与活动而产生任何人身损害及/或财物损失，我们对此不承担任何责任。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"同意并接受", nil];
        alert.tag = kEventDisclaimerAlertTag;
        [alert show];
    }
    
    [self addRefreshControll];
    
    if (INTERNET_AVAILABLE) {
        [self pullDataFromServerWithMemorizedLocation];
    } else {
        [self pullDataFromLocal];
    }
    
    __weak EventVC *weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        if (!INTERNET_AVAILABLE) {
            [weakSelf pullDataFromLocal];
        }
        [weakSelf.tableView.infiniteScrollingView stopAnimating];
    }];
    
}

-(void)addRefreshControll{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[PFUser currentUser] refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
    }];
    [Flurry logEvent:@"View event" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"View event" withParameters:nil];
    [self.fetchQuery cancel];
    [self.refreshControl endRefreshing];
}

-(void)pullDataFromServerWithMemorizedLocation
{
    NSDictionary *dictionary = [Helper userLocation];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    [self pullDataFromServerAroundCenter:center];
}

#pragma mark - Getter

- (NSDateFormatter *)dateFormatter
{
    if(!_dateFormatter){
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    
    return _dateFormatter;
}

#pragma mark - Override

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
    self.fetchQuery = [[PFQuery alloc] initWithClassName:className];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    [self.fetchQuery addBoundingCoordinatesToCenter:center radius:@(fetchRadius)];
    [self.fetchQuery orderByAscending:DDCreatedAtKey];
    [self.fetchQuery whereKey:DDIsBadContentKey notEqualTo:@YES];
    
    // Only want to fetch kServerFetchCount items each time
    self.fetchQuery.limit = fetchLimit;
}

-(void)pullDataFromServerAroundCenter:(CLLocationCoordinate2D)center{
    
    [self setupServerQueryWithClassName:managedObjectName fetchLimit:kServerFetchCount fetchRadius:[[self eventRadius] floatValue] dateConditionKey:kLastFetchDateKey];
    
    [self.fetchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count>0) {
            
            _serverDataCount += objects.count;
            
            self.dataSource = [NSMutableArray array];
            
            for (int i = 0; i < objects.count; i++) {
                
                // Insert into local db
                PFObject *parseObject = objects[i];
                
                // Skip duplicates
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:managedObjectName];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.objectId == %@", parseObject.objectId];
                NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
                Event *event;
                if (fetchedObjects.count > 0) {
                    event = fetchedObjects[0];
                } else {
                    event = [NSEntityDescription insertNewObjectForEntityForName:managedObjectName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [event populateFromParseojbect:parseObject];
                }

                [self.dataSource insertObject:event atIndex:0];
            }
            
            [[SharedDataManager sharedInstance] saveContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }];
}

-(void)pullDataFromLocal{
    [self pullDataFromLocalWithEntityName:managedObjectName fetchLimit:kLocalFetchCount + _localDataCount fetchRadius:[[self eventRadius] floatValue]];
}

- (NSArray *)pullDataFromLocalWithEntityName:(NSString *)entityName fetchLimit:(NSUInteger)fetchLimit fetchRadius:(CGFloat)fetchRadius
{
    NSDictionary *dictionary = [Helper userLocation];
    if (!dictionary) {
        return nil;
    }
    
    if (!self.dataSource) {
        self.dataSource = [NSMutableArray array];
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    fetchRequest.includesPendingChanges = NO;
    NSPredicate *excludeBadContent = [NSPredicate predicateWithFormat:@"self.isBadContent.intValue == %d",0];
    // Specify criteria for filtering which objects to fetch. Add geo bounding constraint
    if (dictionary) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
        MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:@(fetchRadius)];
        NSPredicate *predicate = [NSPredicate geoBoundAndStickyPostPredicateForRegion:region];
        
        NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, excludeBadContent]];
        [fetchRequest setPredicate:compoundPredicate];
    } else {
        [fetchRequest setPredicate:excludeBadContent];
    }
    
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                   ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    fetchRequest.fetchOffset = _localDataCount;
    fetchRequest.fetchLimit = fetchLimit + _localDataCount;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count>0) {
        
        _localDataCount = _localDataCount + fetchedObjects.count;
        [self.dataSource addObjectsFromArray:fetchedObjects];
        
        [self.tableView reloadData];
    }
    
    return fetchedObjects;
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self pullDataFromServerWithMemorizedLocation];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.dataSource == nil || self.dataSource.count == 0) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        return 0;
    } else {
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return self.dataSource.count;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier
                                                                                     forIndexPath:indexPath];
    cell.delegate = self;
    
    Event *event = self.dataSource[indexPath.row];
    cell.flagButton.enabled = !event.isBadContent.boolValue;
    cell.eventNameLabel.text = event.eventName;
    cell.eventDateLabel.text = [self.dateFormatter stringFromDate:event.eventDate];
    cell.eventLocationLabel.text = event.eventLocation;
    cell.eventDescriptionTextView.text = event.eventContent;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (self.dataSource == nil || self.dataSource.count == 0) {
        return 44.0;
    }
    
    Event *event = self.dataSource[indexPath.row];
    //status.statusCellHeight defaults to 0, so cant check nil
    if (event.cellHeight.floatValue != 0) {
        return event.cellHeight.floatValue;
    }else{
        return 200;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    Event *event = self.dataSource[indexPath.row];
    
    //is cell height has been calculated, return it
    if (event.cellHeight.floatValue != 0 ) {
        
        return event.cellHeight.floatValue;
        
    }else{

        CGSize size = CGSizeMake([EventTableViewCell eventLablesWidth], MAXFLOAT);
        CGRect nameRect = [event.eventName boundingRectWithSize:size
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName:[EventTableViewCell fontForEventName]}
                                                        context:NULL];
        CGRect dateRect = [[self.dateFormatter stringFromDate:event.eventDate]
                           boundingRectWithSize:size
                           options:NSStringDrawingUsesLineFragmentOrigin
                           attributes:@{NSFontAttributeName:[EventTableViewCell fontForEventDate]}
                           context:NULL];
        CGRect locationRect = [event.eventLocation boundingRectWithSize:size
                                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                             attributes:@{NSFontAttributeName:[EventTableViewCell fontForEventLocation]}
                                                                context:NULL];
        CGRect descriptionRect = [event.eventContent boundingRectWithSize:size
                                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                                               attributes:@{NSFontAttributeName:[EventTableViewCell fontForEventDescription]}
                                                                  context:NULL];
        
        event.cellHeight = [NSNumber numberWithFloat:CGRectGetMaxY(nameRect) + 5 + dateRect.size.height + 5 + locationRect.size.height + 5 + descriptionRect.size.height + 20 + 50];//50 is for flag button
        [[SharedDataManager sharedInstance] saveContext];
        return event.cellHeight.floatValue;
    }

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0f;
}

#pragma mark - Location

//override
- (void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    [super locationManager:manager didUpdateLocation:location];
    //on viewDidLoad, fetch data for user once, if user wishes to see new data, user needs to pull down and refresh
    //on viewDidLoad, location manager may have not located the user yet, so in this method, is self.dataSource is nil or count ==0, that means we need to manually trigger fetch
    //pull to refresh would always use the location in NSUserDefaults
    if(self.dataSource == nil || self.dataSource.count == 0){
        [self pullDataFromServerAroundCenter:location.coordinate];
    }
}

#pragma mark - EventTableViewCellDelegate

- (void)flagBadContentButtonTappedOnCell:(EventTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __block Event *event = self.dataSource[indexPath.row];
    [self flagObjectForId:event.objectId parseClassName:managedObjectName completion:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            event.isBadContent = @YES;
            [[SharedDataManager sharedInstance] saveContext];
            cell.flagButton.enabled = NO;
        }
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kEventDisclaimerAlertTag) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:kEventDisclaimerKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

@end

