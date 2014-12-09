//
//  GenericTableViewController.m
//  CIU
//
//  Created by Huang, Jason on 8/15/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "GenericTableViewController.h"
#import "Helper.h"
@interface GenericTableViewController()<UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate, CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *previousLocation;
@end
@implementation GenericTableViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self addMenuButton];
    if (!self.locationManager) {
        self.locationManager = [Helper initLocationManagerWithDelegate:self];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)addMenuButton{
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonTapped:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"3menu"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(menuButtonTapped:)];
}

- (void)addTapToScrollUpGesture{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navBarTapped:)];
    [self.navigationController.navigationBar addGestureRecognizer:tap];
}

-(void)addRefreshControll{

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlTriggered:) forControlEvents:UIControlEventValueChanged];
}

-(void)menuButtonTapped:(id)sender{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarSlideOpen" object:self];
}

-(void)navBarTapped:(id)sender{
    [self.tableView scrollsToTop];
}

-(void)refreshControlTriggered:(UIRefreshControl *)sender{
    //override by subclass
}

-(void)pullDataFromLocal{
    //override by subclass
}

-(void)pullDataFromServer{
    //override by subclass
}

-(void)loadRemoteDataForVisibleCells{
    //override by subclass
}

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{
    //override by subclass
}

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    [self cancelRequestsForIndexpath:indexPath];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    [self cancelNetworkRequestForCell:cell atIndexPath:indexPath];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadRemoteDataForVisibleCells];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        [self loadRemoteDataForVisibleCells];
    }
}

#pragma mark - location manager helper

- (void)locationManager:(CLLocationManager *)manager didUpdateLocation:(CLLocation *)location{
    //override by subclass
}
#pragma mark -- Location manager

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [manager startUpdatingLocation];
        NSLog(@"+++++++++++++++++++++++Start updating location+++++++++++++++++++");
    }
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //the most recent location update is at the end of the array.
    CLLocation *location = (CLLocation *)[locations lastObject];

    //-didUpdateLocations gets called very frequently. dont fetch server until there is significant location update
    if (self.previousLocation) {
        CLLocationDistance distance = [location distanceFromLocation:self.previousLocation];
        if(distance/1609 < 10){
            return;
        }
    }
    self.previousLocation = location;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:location.coordinate.latitude],@"latitude",[NSNumber numberWithDouble:location.coordinate.longitude],@"longitude", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self locationManager:manager didUpdateLocation:location];
    
    NSLog(@"+++++++++++++++++++++++Did Update location: %f %f+++++++++++++++++++", location.coordinate.latitude, location.coordinate.longitude);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    NSLog(@"+++++++++++++++++++++++Updating location error: %@+++++++++++++++++++", error);
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                
                if ([CLLocationManager locationServicesEnabled]) {
                    //that means user disabled our app specifically
                    NSLog(@"fail to locate user: permission denied");
//                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kLocationServiceDisabledAlertTitle message:kLocationServiceDisabledAlertMessage delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
//                    [alert show];
                }
                
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
