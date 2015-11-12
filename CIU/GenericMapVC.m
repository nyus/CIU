//
//  GenericMapVC.m
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <Masonry.h>
#import <CoreData/CoreData.h>
#import "GenericMapVC.h"
#import "NSPredicate+Utilities.h"
#import "CustomMKPointAnnotation.h"
#import "LifestyleObject.h"
#import "PFQuery+Utilities.h"
#import "LifestyleObject+Utilities.h"
#import "SharedDataManager.h"
#import "LifestyleObjectDetailTableVC.h"
#import "Helper.h"

static CGFloat const kMilePerDelta = 69.0;
static CLLocationDegrees latitudeDelta = 1.5 / kMilePerDelta;
static CLLocationDegrees longitudeDelta = 1 / kMilePerDelta;
static NSString *const kToObjectDetailVCSegueID = @"toObjectDetail";

@interface GenericMapVC () <MKMapViewDelegate>

@property (nonatomic, strong) UIButton *redoResearchButton;
@property (nonatomic, assign) BOOL isMapLoaded;

@end

@implementation GenericMapVC

- (instancetype)init
{
    self = [super init];
    
    if (self) {
    self.isInternetPresentOnLaunch = [Reachability canReachInternet];
        self.mapViewDataSource = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    _mapView = [[MKMapView alloc] init];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    [_mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(0.0));
        make.bottom.equalTo(@(0.0));
        make.left.equalTo(@(0.0));
        make.right.equalTo(@(0.0));
    }];
    
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
    [self.view addSubview:_redoResearchButton];
    
    __weak typeof(self) weakSelf = self;
    [_redoResearchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@(240.0));
        make.centerX.equalTo(weakSelf.view.mas_centerX);
        make.height.equalTo(@(44.0));
        make.bottom.equalTo(@(-10));
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.mapView.showsUserLocation = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.mapView.showsUserLocation = NO;
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

#pragma mark - Override by subclass

- (NSString *)serverDataParseClassName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -serverDataParseClassName"
                                 userInfo:nil];
}

- (NSString *)localDataEntityName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -localDataEntityName"
                                 userInfo:nil];
}

- (float)serverFetchCount
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -serverFetchCount"
                                 userInfo:nil];
}

- (float)localFetchCount
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -localFetchCount"
                                 userInfo:nil];
}

- (NSString *)keyForLocalDataSortDescriptor
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -keyForLocalDataSortDescriptor"
                                 userInfo:nil];
}

- (BOOL)orderLocalDataInAscending
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -orderLocalDataInAscending"
                                 userInfo:nil];
}

- (NSString *)lifestyleObjectCategory
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass must override -lifestyleObjectCategory"
                                 userInfo:nil];
}

#pragma mark - MapView data

- (NSPredicate *)badContentPredicate
{
    return [NSPredicate predicateWithFormat:@"self.isBadContent.intValue == %d",0];
}

- (NSPredicate *)badLocalContentPredicate
{
    return [NSPredicate predicateWithFormat:@"(self.isBadContentLocal.intValue == %d) OR (self.isBadContentLocal == nil)",0];
}

- (NSPredicate *)geoBoundPredicateWithFetchRadius:(CGFloat)fetchRadius
{
    NSDictionary *dictionary = [Helper userLocation];
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake([dictionary[DDLatitudeKey] doubleValue],
                                                               [dictionary[DDLongitudeKey] doubleValue]);
    MKCoordinateRegion region = [Helper fetchDataRegionWithCenter:center
                                                           radius:@(fetchRadius)];
    return [NSPredicate boudingCoordinatesPredicateForRegion:region];
}

//- (NSFetchRequest *)localDataFetchRequestWithEntityName:(NSString *)entityName
//                                             fetchLimit:(NSUInteger)fetchLimit
//                                             predicates:(NSArray *)predicates
//{
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
//    fetchRequest.includesPendingChanges = NO;
//    
//    // Predicate
//    
//    NSCompoundPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
//    [fetchRequest setPredicate:compoundPredicate];
//    
//    // Sort descriptor
//    
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:[self keyForLocalDataSortDescriptor]
//                                                                   ascending:[self orderLocalDataInAscending]];
//    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
//    
//    fetchRequest.fetchLimit = fetchLimit;
//    
//    return fetchRequest;
//}

//-(void)fetchLocalDataWithRegion:(MKCoordinateRegion)region
//{
//    
//    self.mapViewDataSource = nil;
//    self.mapViewDataSource = [NSMutableArray array];
//    
//    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@", self.lifestyleObjectCategory];
//    NSPredicate *geoLocationPredicate = [NSPredicate boudingCoordinatesPredicateForRegion:region];
//    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithEntityName:self.localDataEntityName
//                                                                  fetchLimit:self.localFetchCount
//                                                                  predicates:@[[self badContentPredicate],
//                                                                               [self badLocalContentPredicate],
//                                                                               categoryPredicate,
//                                                                               geoLocationPredicate]];
//    
//    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext
//                               executeFetchRequest:fetchRequest
//                               error:nil];
//    
//    if (fetchedObjects.count > 0) {
//        
//        [self.mapViewDataSource addObjectsFromArray:fetchedObjects];
//        
//        //new annotaions to add
//        NSMutableArray *coors = [NSMutableArray array];
//        for (LifestyleObject * managedObject in fetchedObjects) {
//            
//            CustomMKPointAnnotation *pin = [[CustomMKPointAnnotation alloc] init];
//            pin.coordinate = CLLocationCoordinate2DMake(managedObject.latitude.doubleValue, managedObject.longitude.doubleValue);
//            pin.title = managedObject.name;
//            pin.subtitle = managedObject.category;
//            pin.lifetstyleObject = managedObject;
//            pin.needAnimation = NO;
//            [coors addObject:pin];
//            
//        }
//        [self.mapView addAnnotations:coors];
//    }
//}

-(void)fetchServerDataWithRegion:(MKCoordinateRegion)region
{
    
    if (self.fetchQuery) {
        [self.fetchQuery cancel];
        self.fetchQuery = nil;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.fetchQuery = [[PFQuery alloc] initWithClassName:self.serverDataParseClassName];
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

#pragma mark - MapView Delegate

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    // Only zoom if it's the first time locating the user
    if (!self.isMapLoaded) {
        
        MKCoordinateRegion region = mapView.region;
        region.center = userLocation.coordinate;
        //show an area whose north to south distance is 1.5 miles and west to east 1 mile
        
        region.span = MKCoordinateSpanMake(latitudeDelta,longitudeDelta);
        [mapView setRegion:region animated:NO];
        
        self.isMapLoaded = YES;
        [UIView animateWithDuration:.8 animations:^{
            
        } completion:^(BOOL finished) {
            
            if (self.isInternetPresentOnLaunch) {
                [self fetchServerDataWithRegion:mapView.region];
            }
        }];
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
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LifestyleObjectDetailTableVC *vc =[storyBoard instantiateViewControllerWithIdentifier:@"restaurantMarketDetailVC"];
    vc.lifestyleObject = annotation.lifetstyleObject;
    
    [self.navigationController pushViewController:vc  animated:YES];
}

@end
