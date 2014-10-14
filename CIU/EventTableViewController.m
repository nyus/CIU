//
//  EventTableViewController.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "EventTableViewController.h"
#import "Event.h"
#import "Event+Utilities.h"
#import "EventTableViewCell.h"
#import "PFQuery+Utilities.h"
#import "NSPredicate+Utilities.h"
#import "Helper.h"

static NSString *managedObjectName = @"Event";
@interface EventTableViewController()<UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate>{
    CLLocation *previousLocation;
}
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation EventTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
 
    [self addRefreshControll];
    
    if (![Reachability canReachInternet]) {
        [self pullDataFromLocal];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager startUpdatingLocation];
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    self.dateFormatter = nil;
}

#pragma mark - Override
-(void)pullDataFromServerAroundCenter:(CLLocationCoordinate2D)center{
    PFQuery *query = [[PFQuery alloc] initWithClassName:managedObjectName];
    [query orderByDescending:@"createdAt"];
    [query addBoundingCoordinatesToCenter:center];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count>0) {
            
            
            if (!self.dataSource) {
                self.dataSource = [NSMutableArray array];
            }
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (int i =0; i<self.dataSource.count; i++) {
                Event *event = self.dataSource[i];
                [dict setValue:[NSNumber numberWithInteger:i] forKey:event.objectId];
            }
            
            for (int i =0; i<objects.count; i++) {
                PFObject *parseObject = objects[i];
                NSNumber *index = [dict valueForKey:parseObject.objectId];
                if (index) {
                    //update
                    Event *event = self.dataSource[index.intValue];
                    //only if we need to update
                    if ([event.updatedAt compare:parseObject.updatedAt] == NSOrderedAscending) {
                        [event populateFromParseojbect:parseObject];
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }
                }else{
                    //insert
                    Event *event = [NSEntityDescription insertNewObjectForEntityForName:managedObjectName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [event populateFromParseojbect:parseObject];
                    [self.dataSource addObject:event];
                    NSIndexPath *path = [NSIndexPath indexPathForRow:self.dataSource.count==0?0:self.dataSource.count-1 inSection:0];
                    [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [[SharedDataManager sharedInstance] saveContext];
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.refreshControl endRefreshing];
        });
    }];
}

-(void)pullDataFromLocal{
    self.dataSource = nil;
    self.dataSource = [NSMutableArray array];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:managedObjectName];
    // Specify criteria for filtering which objects to fetch. Add geo bounding constraint
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"userLocation"];
    if (dictionary) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
        MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:-1];
        NSPredicate *predicate = [NSPredicate boudingCoordinatesPredicateForRegion:region];
        [fetchRequest setPredicate:predicate];
    }
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                   ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count!=0) {
        [self.dataSource addObjectsFromArray:fetchedObjects];
        [self.tableView reloadData];
    }
}

-(void)loadRemoteDataForVisibleCells{}

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{}

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"userLocation"];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
    [self pullDataFromServerAroundCenter:center];
}

#pragma mark - Table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    Event *event = self.dataSource[indexPath.row];
    cell.eventNameLabel.text = event.eventName;
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
        
        event.cellHeight = [NSNumber numberWithFloat:CGRectGetMaxY(nameRect)+5+dateRect.size.height+5+locationRect.size.height+5+descriptionRect.size.height+20];
        [[SharedDataManager sharedInstance] saveContext];
        return event.cellHeight.floatValue;
    }

}
#pragma mark -- Location manager

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //the most recent location update is at the end of the array.
    CLLocation *location = (CLLocation *)[locations lastObject];
    
    //-didUpdateLocations gets called very frequently. dont fetch server until there is significant location update
    if (previousLocation) {
        CLLocationDistance distance = [location distanceFromLocation:previousLocation];
        if(distance/1609 < 10){
            return;
        }
    }
    previousLocation = location;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:location.coordinate.latitude],@"latitude",[NSNumber numberWithDouble:location.coordinate.longitude],@"longitude", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self pullDataFromServerAroundCenter:location.coordinate];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:kLocationServiceDisabledAlert delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                [alert show];
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

