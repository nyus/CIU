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

static CGFloat const kMilePerDelta = 69.0;
static NSString *const kEntityName = @"LifestyleObject";

@interface GenericListMapVC () <MKMapViewDelegate>

@property (nonatomic, strong) UIButton *redoResearchButton;
@property (nonatomic, assign) BOOL isMapLoaded;
@property (nonatomic, strong) NSMutableArray *mapViewDataSource;

@end

@implementation GenericListMapVC

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Getter

- (MKMapView *)mapView
{
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        
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
            _redoResearchButton.hidden = YES;
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

#pragma mark - Fetch map data

- (NSFetchRequest *)localDataFetchRequestWithRegion:(MKCoordinateRegion)region
                                       categoryType:(DDCategoryType)categoryType
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"LifestyleObject"];
    // Predicate
    NSPredicate *excludeBadContent = [NSPredicate predicateWithFormat:@"self.isBadContent == %@", @NO];
    NSPredicate *excludeLocalBadContent = [NSPredicate predicateWithFormat:@"(self.isBadContentLocal.intValue == %d) OR (self.isBadContentLocal == nil)",0];
    NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@",[LifestyleCategory getParseClassNameForCategoryType:self.categoryType]];
    if (categoryType != DDCategoryTypeJob) {
        NSPredicate *geoLocation = [NSPredicate boudingCoordinatesPredicateForRegion:region];
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludeBadContent, excludeLocalBadContent, geoLocation, categoryPredicate]];
    } else {
        fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[excludeBadContent, excludeLocalBadContent, categoryPredicate]];
    }
    // Sort descriptor
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    return fetchRequest;
}

-(void)fetchLocalDataWithRegion:(MKCoordinateRegion)region{
    
    self.mapViewDataSource = nil;
    self.mapViewDataSource = [NSMutableArray array];
    
    [self localDataFetchRequestWithEntityName:<#(NSString *)#> fetchLimit:<#(NSUInteger)#> fetchRadius:<#(CGFloat)#> greaterOrEqualTo:<#(NSDate *)#> lesserOrEqualTo:<#(NSDate *)#> predicates:<#(NSArray *)#>]
    
    
    NSFetchRequest *fetchRequest = [self localDataFetchRequestWithRegion:region
                                                            categoryType:self.categoryType];
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:nil];
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
    
    NSString *parseClassName = [LifestyleCategory getParseClassNameForCategoryType:self.categoryType];
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
                        [life populateFromParseObject:object];
                    }
                }else{
                    //insert new item
                    LifestyleObject *life = [NSEntityDescription insertNewObjectForEntityForName:@"LifestyleObject" inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [life populateFromParseObject:object];
                    [self.mapViewDataSource addObject:life];
                    
                    CLLocationCoordinate2D coordinate =CLLocationCoordinate2DMake([object[@"latitude"] doubleValue], [object[@"longitude"] doubleValue]);
                    CustomMKPointAnnotation *pin = [[CustomMKPointAnnotation alloc] init];
                    pin.coordinate = coordinate;
                    pin.title = object[@"name"];
                    pin.subtitle = object[@"category"];
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

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    self.redoResearchButton.hidden = NO;
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    // Only zoom if it's the first time locating the user
    if (!self.isMapLoaded) {
        
        [mapView setCenterCoordinate:userLocation.coordinate animated:NO];
        MKCoordinateRegion region = mapView.region;
        region.center = userLocation.coordinate;
        //show an area whose north to south distance is 1.5 miles and west to east 1 mile
        static CLLocationDegrees latitudeDelta = 1.5 / kMilePerDelta;
        static CLLocationDegrees longitudeDelta = 1 / kMilePerDelta;
        region.span = MKCoordinateSpanMake(latitudeDelta,longitudeDelta);
        [mapView setRegion:region animated:NO];
        
        [UIView animateWithDuration:.3 animations:^{
        } completion:^(BOOL finished) {
            [self fetchLocalDataWithRegion:mapView.region];
            [self fetchServerDataWithRegion:mapView.region];
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
    lifestyleToPass = annotation.lifetstyleObject;
    //push to detail
    [self performSegueWithIdentifier:kToObjectDetailVCSegueID sender:self];
}

@end
