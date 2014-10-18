//
//  LifestyleDetailViewController.m
//  CIU
//
//  Created by Huang, Jason on 8/22/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
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
#define FETCH_COUNT 20
#define MILE_PER_DELTA 69.0
#define IS_JOB_TRADE [self.categoryName isEqualToString:@"Jobs"] || [self.categoryName isEqualToString:@"Trade and Sell"]
#define IS_RES_MARKT [self.categoryName isEqualToString:@"Restaurant"] || [self.categoryName isEqualToString:@"Supermarket"]
#define IS_JOB [self.categoryName isEqualToString:@"Jobs"]
#define IS_TRADE [self.categoryName isEqualToString:@"Trade and Sell"]

@interface LifestyleDetailViewController()<LoadingTableViewCellDelegate,CLLocationManagerDelegate,MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>{
    BOOL mapRenderedOnStartup;
    LifestyleObject *lifestyleToPass;
    CLLocation *previousLocation;
    BOOL isOffline;
    BOOL forceReload;
}

@property (nonatomic, strong) Query *query;
@property (nonatomic, strong) PFQuery *pfQuery;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;
@property (nonatomic, strong) NSMutableArray *tableViewDataSource;
//@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@end

@implementation LifestyleDetailViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    
    isOffline = ![Reachability canReachInternet];
    
    if (IS_RES_MARKT) {
        self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"List",@"Map"]];
        [self.segmentedControl addTarget:self
                             action:@selector(segmentedControlTapped:)
                   forControlEvents:UIControlEventValueChanged];
        self.segmentedControl.selectedSegmentIndex = 0;
        self.navigationItem.titleView = self.segmentedControl;
    }else if (IS_JOB_TRADE) {
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
        self.navigationItem.rightBarButtonItem = rightItem;
    }
    
//    self.internetReachability = [Reachability reachabilityForInternetConnection];
//	[self.internetReachability startNotifier];
    
    if(isOffline){
        [self fetchLocalDataForList];
    }else{
        if (IS_JOB_TRADE) {
            //jobs, trade and sell don't need location info yet
            [self fetchServerDataForListAroundCenter:CLLocationCoordinate2DMake(0, 0)];
            
        }else if (IS_RES_MARKT) {
            self.locationManager = [Helper initLocationManagerWithDelegate:self];
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    self.mapView.showsUserLocation = NO;
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
    }else{
    //map view
        self.mapView.showsUserLocation = YES;
        [UIView animateWithDuration:.3 animations:^{
            self.tableView.alpha = 0.0f;
            self.mapView.alpha = 1.0f;
        }];
    }
}

-(void)fetchLocalDataWithRegion:(MKCoordinateRegion)region{
    
    self.mapViewDataSource = nil;
    self.mapViewDataSource = [NSMutableArray array];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LifestyleObject"];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate boudingCoordinatesPredicateForRegion:region];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
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
                    pin.needAnimation = YES;
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

-(void)fetchLocalDataForList{

    if (!self.tableViewDataSource) {
        self.tableViewDataSource = [NSMutableArray array];
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"LifestyleObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
    [fetchRequest setEntity:entity];
    
    //sort descriptor
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
    
    // Specify criteria for filtering which objects to fetch
    //1 mile = 1609 meters
    NSPredicate *predicate2;
    if (IS_RES_MARKT) {
        NSDictionary *dictionary = [Helper userLocation];
        if (dictionary) {
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
            MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:nil];
            predicate2 = [NSPredicate boudingCoordinatesPredicateForRegion:region];
        }
    }

    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@",[Helper getParseClassNameForCategoryName:self.categoryName]];
    if (predicate2) {
        NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1,predicate2]];
        fetchRequest.predicate = compoundPredicate;
    }else{
        fetchRequest.predicate = predicate1;
    }
    
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    //
    fetchRequest.fetchLimit = FETCH_COUNT;
    fetchRequest.fetchOffset = self.tableViewDataSource.count;

    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects.count>0) {
        
        int originalCount = self.tableViewDataSource.count;
        NSMutableArray *indexPathsArray = [NSMutableArray array];
        for (int i =originalCount; i<originalCount+fetchedObjects.count; i++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPathsArray addObject:path];
        }
        [self.tableViewDataSource addObjectsFromArray:fetchedObjects];
        [self.tableView insertRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(void)fetchServerDataForListAroundCenter:(CLLocationCoordinate2D)center{
    
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
    [self.pfQuery orderByDescending:@"createdAt"];
    if (IS_RES_MARKT) {
        [self.pfQuery addBoundingCoordinatesToCenter:center radius:nil];
    }
    self.pfQuery.limit = FETCH_COUNT;
    self.pfQuery.skip = self.tableViewDataSource.count;
    [self.pfQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error && objects>0) {
            
            if(!weakSelf.tableViewDataSource){
                weakSelf.tableViewDataSource = [NSMutableArray array];
            }
            
            //construct array of indexPath and store parse data to local
            NSMutableArray *indexpathArray = [NSMutableArray array];
             int originalCount = (int)weakSelf.tableViewDataSource.count;
            __block int i = 0;
            for (PFObject *parseObject in objects) {

                dispatch_async(dispatch_get_main_queue(), ^{
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
                    NSIndexPath *path = [NSIndexPath indexPathForRow:i+originalCount inSection:0];
                    [indexpathArray addObject:path];
                    [weakSelf.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
                    i++;
                });
            }
        }
    }];
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
    
    //job and trade doesnt require location information
    if (IS_RES_MARKT && (self.tableViewDataSource == nil || self.tableViewDataSource.count == 0)) {
        [self fetchServerDataForListAroundCenter:location.coordinate];
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
        GenericTableViewCell *cell = (GenericTableViewCell *)[tableView dequeueReusableCellWithIdentifier:jobAndTradeCell forIndexPath:indexPath];
        cell.contentLabel.text = object.content;
        cell.contentLabel.font = [UIFont systemFontOfSize:14.0f];
        return cell;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section==0 && ![self.categoryName isEqualToString:@"Jobs"]) {
        return @"Display items within 30 miles around you.";
    }else{
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (IS_RES_MARKT) {
        return 44;
    } else {
        LifestyleObject *object = self.tableViewDataSource[indexPath.row];
        NSString *content = object.content;
        CGRect rect = [content boundingRectWithSize:CGSizeMake(280, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]} context:NULL];
        
        if (rect.size.height<44.0f) {
            return 44.0f;
        } else {
            //5.0f is becuase the top margin is 5 pixels
            return rect.size.height+5.0f;
        }
    }
}

#pragma mark - loading cell delegate 

-(void)browseMoreButtonTappedOnCell:(UITableViewCell *)cell{
    if(isOffline){
        [self fetchLocalDataForList];
    }else{

        if(IS_RES_MARKT){
            
            NSDictionary *dictionary = [Helper userLocation];
            if (dictionary) {
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
                [self fetchServerDataForListAroundCenter:center];
            }
            
        }else if(IS_JOB_TRADE){
            
            NSDictionary *dictionary = [Helper userLocation];
            if (dictionary) {
                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
                MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center radius:nil];
                [self fetchServerDataWithRegion:region];
            }
            
        }else{
            return;
        }
    }
}

#pragma mark - map delegate

- (void)mapViewDidFinishRenderingMap:(MKMapView *)mapView fullyRendered:(BOOL)fullyRendered{
    
    if (fullyRendered && mapView.alpha == 1.0) {
        [self fetchLocalDataWithRegion:mapView.region];
        [self fetchServerDataWithRegion:mapView.region];
    }
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    [mapView setCenterCoordinate:userLocation.coordinate animated:YES];
    MKCoordinateRegion region = mapView.region;
    region.center = userLocation.coordinate;
    //show an area whose north to south distance is 1.5 miles and west to east 1 mile
    static CLLocationDegrees latitudeDelta = 1.5/MILE_PER_DELTA;
    static CLLocationDegrees longitudeDelta = 1/MILE_PER_DELTA;
    region.span = MKCoordinateSpanMake(latitudeDelta,longitudeDelta);
    [mapView setRegion:region animated:YES];
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    
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

#pragma mark -- reachability 

/*!
 * Called by Reachability whenever status changes.
 */
//- (void) reachabilityChanged:(NSNotification *)note
//{
//    //if previously offline and now there is internet connection
//    static int count = 0;
//    if(count == 0 && [Reachability canReachInternet] && isOffline == YES){
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You are now connected to the internet. Would you like to display up-to-date information around you?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
//        alert.tag = 99;
//        [alert show];
//        count =1;
//    }
//}

#pragma mark - uialertview delegate

//-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
//    //would like to update information alert in -reachabilityChanged
//    if(alertView.tag == 99){
//        //YES
//        if(buttonIndex == 1){
//            isOffline = NO;
//            if(self.segmentedControl.selectedSegmentIndex == 0){
//                self.tableViewDataSource = nil;
//                [self.tableView reloadData];
//            }else if (self.segmentedControl.selectedSegmentIndex == 1){
//                self.mapViewDataSource = nil;
//                //remove annotations
//                if (self.mapView.annotations.count!=0) {
//                    NSInteger toRemoveCount = self.mapView.annotations.count;
//                    NSMutableArray *toRemove = [NSMutableArray arrayWithCapacity:toRemoveCount];
//                    for (id annotation in self.mapView.annotations)
//                        if (annotation != self.mapView.userLocation)
//                            [toRemove addObject:annotation];
//                    [self.mapView removeAnnotations:toRemove];
//                }
//            }
//            [self.locationManager startUpdatingLocation];
//        }
//    }
//}

@end
