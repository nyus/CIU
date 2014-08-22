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
#warning do setups to be able to use MapKit in the app store.https://developer.apple.com/library/ios/documentation/userexperience/Conceptual/LocationAwarenessPG/MapKit/MapKit.html#//apple_ref/doc/uid/TP40009497-CH3-SW1. see "Displaying Maps" section: To use the features of the Map Kit framework, turn on the Maps capability in your Xcode project (doing so also adds the appropriate entitlement to your App ID). Note that the only way to distribute a maps-based app is through the iOS App Store or Mac App Store. If you’re unfamiliar with entitlements, code signing, and provisioning, start learning about them in App Distribution Quick Start. For general information about the classes of the Map Kit framework, see Map Kit Framework Reference.

@interface LifestyleDetailViewController()<MKMapViewDelegate>
@property (nonatomic, strong) Query *query;
@end

@implementation LifestyleDetailViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.mapView.showsUserLocation = YES;
}

-(void)fetchLocalDataWithCenter:(CLLocationCoordinate2D) center{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@""];
    //only fetch objects within certain perimeter
    CLLocationDegrees maxLat = 0;
    CLLocationDegrees minLat = 0;
    CLLocationDegrees maxLong = 0;
    CLLocationDegrees minLong = 0;
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.lat>%f && self.lat<%f && self.long>%@ && self.long<%f", minLat,maxLat,minLong,maxLong];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count>0) {
        
    }
}

-(void)fetchServerDataWithCenter:(CLLocationCoordinate2D)center{
    
    if (self.query) {
        [self.query cancelRequest];
        self.query = nil;
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.query = [[Query alloc] init];
    [self.query fetchObjectsOfType:@"Supermarket" center:center radius:50 completion:^(NSError *error, NSArray *results) {
        if (!error && results.count>0) {
            
        }
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }];

}

#pragma mark - map delegate

-(void)mapViewWillStartLocatingUser:(MKMapView *)mapView{

}

-(void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error{
    
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    [self fetchLocalDataWithCenter:userLocation.coordinate];
    [mapView setCenterCoordinate:userLocation.coordinate animated:YES];
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:
                
            case kCLErrorLocationUnknown:
                
            default:
                break;
        }
    } else {
        // We handle all non-CoreLocation errors here
    }
}

@end
