//
//  EventTableViewController.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "EventTableViewController.h"
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

static NSString *managedObjectName = @"Event";
static NSString *const kEventDataRadiusKey = @"kEventDataRadiusKey";

static NSInteger const kEventDisclaimerAlertTag = 50;
static NSString *const kEventDisclaimerKey = @"kEventDisclaimerKey";

@interface EventTableViewController()<UITableViewDataSource,UITableViewDelegate, EventTableViewCellDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DisplayPeripheralHeaderView *headerView;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong, readwrite) NSNumber *eventRadius;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation EventTableViewController{
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
        _headerView = [[DisplayPeripheralHeaderView alloc] initWithStepValue:[self eventRadius] minimunStepValue:@5 maximunStepValue:@80 actionBlock:^(double newValue) {
            [[GAnalyticsManager shareManager] trackUIAction:@"event - change display radius" label:@"event" value:@(newValue)];
            [Flurry logEvent:@"event - change display radius" withParameters:@{@"radius":@(newValue)}];
            [self setEventRadius:@(newValue)];
            [self handleDataDisplayPeripheral];
        }];
    }
    
    return _headerView;
}

-(void)handleDataDisplayPeripheral{
    
    self.dataSource = nil;
    [self.tableView reloadData];
    [self pullDataFromLocal];
    [self pullDataFromServerWithMemorizedLocation];
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[GAnalyticsManager shareManager] trackScreen:@"Event"];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kEventDisclaimerKey]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"请您务必理解并同意，DaDa哒哒仅为信息发布平台，并非活动的主办方或发起人，如您因在参与活动而产生任何人身损害及/或财物损失，我们对此不承担任何责任。" delegate:self cancelButtonTitle:nil otherButtonTitles:@"同意并接受", nil];
        alert.tag = kEventDisclaimerAlertTag;
        [alert show];
    }
    
    [self addRefreshControll];
    
    [self pullDataFromLocal];
    
    if ([Reachability canReachInternet]) {
        [self pullDataFromServerWithMemorizedLocation];
    }
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    __weak EventTableViewController *weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf pullDataFromLocal];
        [weakSelf.tableView.infiniteScrollingView stopAnimating];
    }];
    
}

-(void)addRefreshControll{
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"View event" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"View event" withParameters:nil];
    self.dateFormatter = nil;
}

-(void)pullDataFromServerWithMemorizedLocation
{
    NSDictionary *dictionary = [Helper userLocation];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    [self pullDataFromServerAroundCenter:center];
}

#pragma mark - Override

-(void)pullDataFromServerAroundCenter:(CLLocationCoordinate2D)center{
    
    [self setupServerQueryWithClassName:managedObjectName fetchLimit:kServerFetchCount fetchRadius:[[self eventRadius] floatValue] dateConditionKey:@"lastFetchEventDate"];
    
    [self.fetchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count>0) {
            
            _serverDataCount += objects.count;
            _localDataCount += objects.count;
            
            if (!self.dataSource) {
                self.dataSource = [NSMutableArray array];
            }
            
            NSMutableArray *indexPaths = [NSMutableArray array];
            for (int i = 0; i < objects.count; i++) {
                
                // Insert into local db
                PFObject *parseObject = objects[i];
                Event *event = [NSEntityDescription insertNewObjectForEntityForName:managedObjectName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                [event populateFromParseojbect:parseObject];
                
                [self.dataSource insertObject:event atIndex:0];
                
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                
                if (i == objects.count - 1) {
                    [[NSUserDefaults standardUserDefaults] setObject:parseObject.createdAt forKey:@"lastFetchEventDate"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            
            [[SharedDataManager sharedInstance] saveContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
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

-(void)loadRemoteDataForVisibleCells{}

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{}

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self pullDataFromServerWithMemorizedLocation];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    cell.delegate = self;
    Event *event = self.dataSource[indexPath.row];
    cell.eventNameLabel.text = event.eventName;
    
    if (event.isBadContent.boolValue) {
        cell.flagButton.enabled = NO;
    }else{
        cell.flagButton.enabled = YES;
    }
    
    if(!self.dateFormatter){
        self.dateFormatter = [[NSDateFormatter alloc] init];
        self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
        self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    cell.eventDateLabel.text = [self.dateFormatter stringFromDate:event.eventDate];
    cell.eventLocationLabel.text = event.eventLocation;
    cell.eventDescriptionLabel.text = event.eventContent;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
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
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0f]};
        CGSize size = CGSizeMake(273, MAXFLOAT);
        CGRect nameRect = [event.eventName boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        if(!self.dateFormatter){
            self.dateFormatter = [[NSDateFormatter alloc] init];
            self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
            self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
        }
        CGRect dateRect = [[self.dateFormatter stringFromDate:event.eventDate] boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect locationRect = [event.eventLocation boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect descriptionRect = [event.eventContent boundingRectWithSize:size options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        event.cellHeight = [NSNumber numberWithFloat:CGRectGetMaxY(nameRect)+5+dateRect.size.height+5+locationRect.size.height+5+descriptionRect.size.height+20 + 50];//50 is for flag button
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

    cell.flagButton.enabled = NO;
    
    PFQuery *query = [PFQuery queryWithClassName:managedObjectName];
    [query whereKey:@"objectId" equalTo:event.objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error) {
            NSLog(@"get status object with id:%@ failed",object.objectId);
        } else {
            [object setObject:@YES forKey:@"isBadContent"];
            [object saveEventually:^(BOOL succeeded, NSError *error) {
                event.isBadContent = @YES;
                [[SharedDataManager sharedInstance] saveContext];
            }];
            
            PFObject *audit = [PFObject objectWithClassName:@"Audit"];
            audit[@"auditObjectId"] = object.objectId;
            [audit saveEventually];
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

