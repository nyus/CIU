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
static CLLocationDegrees latitudeDelta = 1.5 / kMilePerDelta;
static CLLocationDegrees longitudeDelta = 1 / kMilePerDelta;

@interface GenericListMapVC ()

@property (nonatomic, strong) UIButton *redoResearchButton;
@property (nonatomic, assign) BOOL isMapLoaded;

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

- (void)fetchLocalDataWithRegion:(MKCoordinateRegion)region
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -fetchLocalDataWithRegion"
                                 userInfo:nil];
}

- (void)fetchServerDataWithRegion:(MKCoordinateRegion)region
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -fetchServerDataWithRegion"
                                 userInfo:nil];
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

@end
