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
static NSString *managedObjectName = @"Event";
static float const kEventRadius = 30;
static float const kServerFetchCount = 50;
static float const kLocalFetchCount = 20;
@interface EventTableViewController()<UITableViewDataSource,UITableViewDelegate, EventTableViewCellDelegate>{
}
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) PFQuery *query;
@end

@implementation EventTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
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
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
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

    if (self.query) {
        [self.query cancel];
        self.query = nil;
    }
    self.query = [[PFQuery alloc] initWithClassName:managedObjectName];
    [self.query orderByDescending:@"createdAt"];
    [self.query addBoundingCoordinatesToCenter:center radius:@(kEventRadius)];
    [self.query whereKey:@"isBadContent" notEqualTo:@YES];
    
    //lastFetchStatusDate is the latest createdAt date among the statuses  last fetched
    NSDate *lastFetchStatusDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastFetchEventDate"];
    if (lastFetchStatusDate) {
        [self.query whereKey:@"createdAt" greaterThan:lastFetchStatusDate];
    }
    
    // Only want to fetch kServerFetchCount items each time
    self.query.limit = kServerFetchCount + _serverDataCount;
    self.query.skip = _serverDataCount;
    
    [self.query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
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
                
                if (i==0) {
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
    
    if (!self.dataSource) {
        self.dataSource = [NSMutableArray array];
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:managedObjectName];
    // Specify criteria for filtering which objects to fetch. Add geo bounding constraint
    NSPredicate *excludeBadContent = [NSPredicate predicateWithFormat:@"self.isBadContent.intValue == %d",0];
    NSDictionary *dictionary = [Helper userLocation];
    if (dictionary) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
        MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:@(kEventRadius)];
        NSPredicate *predicate = [NSPredicate boudingCoordinatesPredicateForRegion:region];
        
        NSCompoundPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate]];
        [fetchRequest setPredicate:p];
    } else {
        [fetchRequest setPredicate:excludeBadContent];
    }
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                   ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    fetchRequest.fetchOffset = _localDataCount;
    fetchRequest.fetchLimit = kLocalFetchCount + _localDataCount;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count!=0) {
        // This has to be called before adding new objects to the data source
        NSUInteger currentCount = self.dataSource.count;
        
        _localDataCount += fetchedObjects.count;
        [self.dataSource addObjectsFromArray:fetchedObjects];
        
        NSMutableArray *indexPaths = [NSMutableArray array];
        
        for (int i = 0; i < fetchedObjects.count; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i + currentCount inSection:0]];
        }
        
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
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

@end

