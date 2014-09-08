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
static NSString *kLocationServiceDisabledAlert = @"To display information around you, please turn on location services at Settings > Privacy > Location Services";
static NSString *managedObjectName = @"Event";
@interface EventTableViewController()<UITableViewDataSource,UITableViewDelegate,CLLocationManagerDelegate>{
    CLLocation *previousLocation;
}
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation EventTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    //seeign a weird issue when the content inset is not adjusted by checking "adjust scroll view insets" in IB
    self.tableView.contentInset = UIEdgeInsetsMake(64, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right);
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //we add a right bar button item on statusViewcOntroller. since all the tabs are sharing the same navigation bar, here we take out the right item
    //add right bar item(compose)
    UITabBarController *tab=self.navigationController.viewControllers[0];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
    tab.navigationItem.rightBarButtonItem = item;
    
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

-(void)addButtonTapped:(id)sender{
    [self performSegueWithIdentifier:@"toCreateEvent" sender:self];
}

#pragma mark - Override
-(void)pullDataFromServerAroundCenter:(CLLocationCoordinate2D)center{
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:managedObjectName];
    [query orderByDescending:@"createdAt"];
    [query addBoundingCoordinatesToCenter:center];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count>0) {
            
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
                    NSIndexPath *path = [NSIndexPath indexPathForRow:self.dataSource.count-1 inSection:0];
                    [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [[SharedDataManager sharedInstance] saveContext];
                }
            }
        }
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
        MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center];
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
    [self pullDataFromServer];
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




