//
//  GenericListMapVC.m
//  DaDa
//
//  Created by Sihang on 9/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <Masonry.h>
#import <MapKit/MapKit.h>
#import "GenericListMapVC.h"
#import "NameAddressTableViewCell.h"
#import "NSPredicate+Utilities.h"
#import "PFQuery+Utilities.h"
#import "LifestyleObject.h"
#import "LifestyleObject+Utilities.h"
#import "LifestyleObjectDetailTableVC.h"

static CGFloat const kMilePerDelta = 69.0;
static NSString *const kEntityName = @"LifestyleObject";
static CLLocationDegrees latitudeDelta = 1.5 / kMilePerDelta;
static CLLocationDegrees longitudeDelta = 1 / kMilePerDelta;
static NSString *const kToObjectDetailVCSegueID = @"toObjectDetail";
static NSString *const kNameAndAddressCellReuseID = @"kNameAndAddressCellReuseID";

@interface GenericListMapVC ()

@property (nonatomic, strong) UIButton *redoResearchButton;
@property (nonatomic, assign) BOOL isMapLoaded;

@end

@implementation GenericListMapVC

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // So that there is navigation back button
        
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[NameAddressTableViewCell class] forCellReuseIdentifier:kNameAndAddressCellReuseID];
}

#pragma mark - Getter

- (MKMapView *)mapView
{
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        _mapView.delegate = self;
        // Can't add mapview to tableview
        [self.view.superview insertSubview:_mapView aboveSubview:self.view];
        [_mapView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(@(0.0));
            make.bottom.equalTo(@(0.0));
            make.left.equalTo(@(0.0));
            make.right.equalTo(@(0.0));
        }];
        
        if (!_redoResearchButton) {
            _redoResearchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            _redoResearchButton.layer.cornerRadius = 10.0;
            _redoResearchButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
            _redoResearchButton.layer.borderWidth = 1.0;
            [_redoResearchButton setTitle:@"Redo search in this area" forState:UIControlStateNormal];
            [_redoResearchButton setTitleColor:[UIColor themeTextGrey] forState:UIControlStateNormal];
            _redoResearchButton.titleLabel.font = [UIFont themeFontWithSize:18.0];
            _redoResearchButton.backgroundColor = [UIColor themeGreen];
            [_redoResearchButton addTarget:self
                                  action:@selector(reSearchButtonTapped:)
                        forControlEvents:UIControlEventTouchUpInside];
        }
        
        [_mapView addSubview:_redoResearchButton];
        [_redoResearchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(240.0));
            make.centerX.equalTo(_mapView);
            make.height.equalTo(@(44.0));
            make.bottom.equalTo(@(-10));
        }];
    }
    
    return _mapView;
}

- (NSString *)lifestyleObjectCategory
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass must override -lifestyleObjectCategory"
                                 userInfo:nil];
}

#pragma mark - Action

- (void)reSearchButtonTapped:(UIButton *)reSearchButton
{
    [self handleRedoSearchButtonTapped];
}

- (void)handleRedoSearchButtonTapped
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -handleRedoSearchButtonTapped"
                                 userInfo:nil];
}

#pragma mark - MapView data

-(void)fetchLocalDataWithRegion:(MKCoordinateRegion)region
{
    
    self.mapViewDataSource = nil;
    self.mapViewDataSource = [NSMutableArray array];
    
    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@", self.lifestyleObjectCategory];
    NSPredicate *geoLocationPredicate = [NSPredicate boudingCoordinatesPredicateForRegion:region];
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithEntityName:self.localDataEntityName
                                                                  fetchLimit:self.localFetchCount
                                                                  predicates:@[[self badContentPredicate],
                                                                               [self badLocalContentPredicate],
                                                                               categoryPredicate,
                                                                               geoLocationPredicate]];
    
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext
                               executeFetchRequest:fetchRequest
                               error:nil];
    
    if (fetchedObjects.count > 0) {
        
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

-(void)fetchServerDataWithRegion:(MKCoordinateRegion)region
{
    
    if (self.fetchQuery) {
        [self.fetchQuery cancel];
        self.fetchQuery = nil;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.fetchQuery = [[PFQuery alloc] initWithClassName:DDRestaurantParseClassName];
    [self.fetchQuery addBoundingCoordinatesConstraintForRegion:region];
    [self.fetchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error) {
            NSLog(@"Failed to fetch restaurants with error: %@", error);
        } else {
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
            
            for (PFObject *object in objects) {
                
                NSNumber *lifeIndex = [map valueForKey:object.objectId];
                
                if (lifeIndex) {
                    //update value
                    LifestyleObject *life = self.mapViewDataSource[lifeIndex.intValue];
                    
                    if ([life.updatedAt compare:object.updatedAt] == NSOrderedAscending) {
                        [life populateFromParseObject:object];
                    }
                    
                } else {
                    //insert new item
                    LifestyleObject *life = [NSEntityDescription insertNewObjectForEntityForName:self.localDataEntityName
                                                                          inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [life populateFromParseObject:object];
                    [self.mapViewDataSource addObject:life];
                    
                    CLLocationCoordinate2D coordinate =CLLocationCoordinate2DMake([object[DDLatitudeKey] doubleValue],
                                                                                  [object[DDLongitudeKey] doubleValue]);
                    CustomMKPointAnnotation *pin = [[CustomMKPointAnnotation alloc] init];
                    pin.coordinate = coordinate;
                    pin.title = object[DDNameKey];
                    pin.subtitle = object[DDCategoryKey];
                    pin.lifetstyleObject = life;
                    pin.needAnimation = NO;
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

#pragma mark - table view

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataSource.count;
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
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LifestyleObjectDetailTableVC *vc =[storyBoard instantiateViewControllerWithIdentifier:@"restaurantMarketDetailVC"];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[NameAddressTableViewCell class]]) {
        vc.lifestyleObject = self.dataSource[indexPath.row];
    } else {
        vc.lifestyleObject = self.lifestyleToPass;
    }
    
    [self.navigationController pushViewController:vc  animated:YES];
}

#pragma mark - MapView Delegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
//    self.redoResearchButton.hidden = NO;
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    // Only zoom if it's the first time locating the user
    if (!self.isMapLoaded) {
        
        [mapView setCenterCoordinate:userLocation.coordinate animated:NO];
        MKCoordinateRegion region = mapView.region;
        region.center = userLocation.coordinate;
        //show an area whose north to south distance is 1.5 miles and west to east 1 mile
        
        region.span = MKCoordinateSpanMake(latitudeDelta,longitudeDelta);
        [mapView setRegion:region animated:NO];
        
        [UIView animateWithDuration:.3 animations:^{
        } completion:^(BOOL finished) {
            
            if (self.isInternetPresentOnLaunch) {
                [self fetchServerDataWithRegion:mapView.region];
            } else {
                [self fetchLocalDataWithRegion:mapView.region];
            }
        }];
        self.isMapLoaded = YES;
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");
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
    self.lifestyleToPass = annotation.lifetstyleObject;
    [self performSegueWithIdentifier:kToObjectDetailVCSegueID sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:kToObjectDetailVCSegueID]){
        
        LifestyleObjectDetailTableVC *vc = (LifestyleObjectDetailTableVC *)segue.destinationViewController;
        
        // from tb view or from map
        
        if ([sender isKindOfClass:[NameAddressTableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            vc.lifestyleObject = self.dataSource[indexPath.row];
        } else {
            vc.lifestyleObject = self.lifestyleToPass;
        }
    }
}

@end
