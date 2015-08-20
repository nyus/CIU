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
#import "DisplayPeripheralHeaderView.h"

static float const kServerFetchCount = 50;
static float const kLocalFetchCount = 20;
static NSString *kEntityName = @"Event";
static NSString *const kEventDataRadiusKey = @"kEventDataRadiusKey";
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
    
    [self.dataSource removeAllObjects];
    [self.tableView reloadData];
    if ([Reachability canReachInternet]) {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:nil];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                               fetchRadius:[[self eventRadius] floatValue]
                          greaterOrEqualTo:nil 
                           lesserOrEqualTo:nil];
    }
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

- (NSString *)serverDataParseClassName
{
    return DDEventParseClassName;
}

- (NSString *)localDataEntityName
{
    return kEntityName;
}

- (float)dataFetchRadius
{
    return [self eventRadius].floatValue;
}

- (float)serverFetchCount
{
    return kServerFetchCount;
}

- (float)localFetchCount
{
    return kLocalFetchCount;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self addRefreshControle];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[PFUser currentUser] fetchInBackground];
    [Flurry logEvent:@"View event" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [Flurry endTimedEvent:@"View event" withParameters:nil];
    [self.fetchQuery cancel];
    [self.refreshControl endRefreshing];
}

#pragma mark - Override

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
    [self.fetchQuery orderByDescending:DDEventDateKey];
    [self.fetchQuery whereKey:DDIsBadContentKey notEqualTo:@YES];
    
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
    [((Event *)managedObject) populateFromParseObject:object];
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

#pragma mark - EventTableViewCellDelegate

- (void)flagBadContentButtonTappedOnCell:(EventTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __block Event *event = self.dataSource[indexPath.row];
    [self flagObjectForId:event.objectId parseClassName:kEntityName completion:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            event.isBadContent = @YES;
            [[SharedDataManager sharedInstance] saveContext];
            cell.flagButton.enabled = NO;
        }
    }];
}

@end

