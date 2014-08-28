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
#define MILE_PER_DELTA 69.0

@interface LifestyleDetailViewController()<CLLocationManagerDelegate,MKMapViewDelegate,UITableViewDataSource,UITableViewDelegate>{
    BOOL mapRenderedOnStartup;
    LifestyleObject *lifestyleToPass;
    BOOL hasDoneInitialTBFetch;
    BOOL noMoreNewFetchedData;
    BOOL offlineMode;
}
@property (nonatomic, strong) Query *query;
@property (nonatomic, strong) PFQuery *pfQuery;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;
@property (nonatomic, strong) NSMutableArray *tableViewDataSource;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation LifestyleDetailViewController

-(void)viewDidLoad{
    [super viewDidLoad];

    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"List",@"Map"]];
    [segmentedControl addTarget:self
                         action:@selector(segmentedControlTapped:)
               forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0;
    self.navigationItem.titleView = segmentedControl;
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
	[self.internetReachability startNotifier];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    if (![Reachability canReachInternet]) {
        
        [self fetchLocalDataForList];
    }else{
        if (!self.locationManager) {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            [self.locationManager startUpdatingLocation];
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    self.mapView.showsUserLocation = NO;
}

-(void)segmentedControlTapped:(UISegmentedControl *)sender{
    //list view
    if (sender.selectedSegmentIndex==0) {

    }else{
    //map view
        self.mapView.showsUserLocation = YES;
        self.mapView.alpha = 1.0f;
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
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.query = [[Query alloc] init];
    [self.query fetchObjectsOfClassName:self.categoryName region:region completion:^(NSError *error, NSArray *results) {
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
    // Specify criteria for filtering which objects to fetch
    //1 mile = 1609 meters
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:@"userLocation"];
    NSPredicate *predicate2;
    if (dictionary) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[@"latitude"] doubleValue], [dictionary[@"longitude"] doubleValue]);
        MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center];
        predicate2 = [NSPredicate boudingCoordinatesPredicateForRegion:region];
    }
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@",self.categoryName];
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
    fetchRequest.fetchLimit = 20;
    fetchRequest.fetchOffset = self.tableViewDataSource.count;
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    hasDoneInitialTBFetch = YES;
    
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
    
    self.pfQuery = [[PFQuery alloc] initWithClassName:self.categoryName];
    [self.pfQuery orderByDescending:@"name"];
    [self.pfQuery addBoundingCoordinatesToCenter:center withinDistance:5];
    self.pfQuery.limit = 20;
    self.pfQuery.skip = self.tableViewDataSource.count;
    [self.pfQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (!error && objects>0) {
            
            noMoreNewFetchedData = NO;
            
            if(!weakSelf.tableViewDataSource){
                weakSelf.tableViewDataSource = [NSMutableArray array];
            }
            
            //construct array of indexPath and store parse data to local
            NSMutableArray *indexpathArray = [NSMutableArray array];
             int originalCount = weakSelf.tableViewDataSource.count;
            for (int i =0; i<objects.count; i++) {
                PFObject *parseObject = objects[i];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.objectId MATCHES[cd] %@",parseObject.objectId];
                NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"LifestyleObject"];
                request.predicate = predicate;
                NSArray *array = [[[SharedDataManager sharedInstance] managedObjectContext] executeFetchRequest:request error:nil];
                LifestyleObject *life;
                if (array.count == 1) {
                    life = array[0];
                    [life populateFromObject:parseObject];
                }else{
                    life = [NSEntityDescription insertNewObjectForEntityForName:@"LifestyleObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [life populateFromObject:parseObject];
                }
                
                NSIndexPath *path = [NSIndexPath indexPathForRow:i+originalCount inSection:0];
                [indexpathArray addObject:path];
                
                [weakSelf.tableViewDataSource addObject:life];
            }
            
            [[SharedDataManager sharedInstance] saveContext];
        
           
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView beginUpdates];
                if (originalCount != [weakSelf.tableView numberOfRowsInSection:0]) {
                    //remove the loading cell
                    NSIndexPath *path = [NSIndexPath indexPathForRow:[weakSelf.tableView numberOfRowsInSection:0]-1 inSection:0];
                    [weakSelf.tableView deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
                }
                [weakSelf.tableView insertRowsAtIndexPaths:indexpathArray withRowAnimation:UITableViewRowAnimationFade];
                [weakSelf.tableView endUpdates];
            });
        }else{
            noMoreNewFetchedData = YES;
        }
        
        if (hasDoneInitialTBFetch==NO) {
            hasDoneInitialTBFetch = YES;
        }
    }];
}

#pragma mark -- Location manager

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //the most recent location update is at the end of the array.
    CLLocation *location = (CLLocation *)[locations lastObject];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:location.coordinate.latitude],@"latitude",[NSNumber numberWithDouble:location.coordinate.longitude],@"longitude", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self fetchServerDataForListAroundCenter:location.coordinate];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Go to Settings > Privacy > Location Services to enable location service" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
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

//-(void)loadRemoteDataForVisibleCells{
//    
//}
//
//-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{
//
//}
//
//-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
//    [self cancelRequestsForIndexpath:indexPath];
//}
//

//
//-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
//    [self cancelNetworkRequestForCell:cell atIndexPath:indexPath];
//}
//
//-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
//    [self loadRemoteDataForVisibleCells];
//}
//
//-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    if (!decelerate) {
//        [self loadRemoteDataForVisibleCells];
//    }
//}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //have reach the last cell. fetch more
    if (indexPath.row == self.tableViewDataSource.count-1 && self.tableViewDataSource.count >=20) {
        if (offlineMode) {
            [self fetchLocalDataForList];
        }else{
#warning change
//            [self fetchServerDataForList];
        }
    }
    
    //    if ([cell.reuseIdentifier isEqualToString:@"loadingCell"] && hasDoneInitialTBFetch == YES) {
    //        [self fetchServerDataForList];
    //    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if (hasDoneInitialTBFetch == NO) {
        //loading cell
        return 1;
    }else{
        
        return self.tableViewDataSource.count;
//        if(noMoreNewFetchedData || self.tableViewDataSource.count<20){
//            return self.tableViewDataSource.count;
//        }else{
//            return self.tableViewDataSource.count+1;
//        }
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *regularCell = @"cell";
    static NSString *loadingCell = @"loadingCell";
    if(hasDoneInitialTBFetch==NO || indexPath.row == self.tableViewDataSource.count){
        return [tableView dequeueReusableCellWithIdentifier:loadingCell forIndexPath:indexPath];
    }else{
        LifestyleObject *object = self.tableViewDataSource[indexPath.row];
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:regularCell forIndexPath:indexPath];
        cell.textLabel.text = object.name;
        cell.detailTextLabel.text = object.address;
        return cell;
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
    
    if (mapView.alpha == 0) {
        return;
    }
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Go to Settings > Privacy > Location Services to enable location service" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
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
        LifestyleObjectDetailTableViewController *vc = (LifestyleObjectDetailTableViewController *)segue.destinationViewController;
        vc.lifestyleObject = lifestyleToPass;
    }
}

#pragma mark -- reachability 

/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    if ([curReach currentReachabilityStatus] != NotReachable) {
        
    }
}

@end
