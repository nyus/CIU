//
//  LocationManager.m
//  CIU
//
//  Created by Sihang on 9/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LocationManager.h"
static CLLocationManager *_manager;
@interface LocationManager()<CLLocationManagerDelegate>
@end

@implementation LocationManager

+(CLLocationManager *)sharedInstance{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _manager = [[CLLocationManager alloc] init];
    });
    return _manager;;
}

//-(void)setDelegate:(id)delegate{
//    _manager.delegate = delegate;
//}


-(CLAuthorizationStatus)authorizationStatus{
    return [CLLocationManager authorizationStatus];
}

-(void)start{
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You device is not allowed to access location information. Probably due to parental control" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You've disabled location services for this app. Please enable it." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }else{
        
        if (![CLLocationManager locationServicesEnabled]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"You've disabled location services. Go to Settings - Privacy - Location Services to enable it." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        
        _manager.delegate = self;
        
        if (IS_IOS_8 && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
            [_manager requestWhenInUseAuthorization];
            return;
        }
        
        //if significant is availabe, use it, otherwise user standard location service
        if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
            [_manager startMonitoringSignificantLocationChanges];
        }else{
            NSNumber *distance = [[NSUserDefaults standardUserDefaults] objectForKey:@"distanceFilter"];
            if (distance) {
                _manager.distanceFilter = distance.intValue;
            }else{
                _manager.distanceFilter = 2*1609;//every 2 miles
            }
            _manager.desiredAccuracy = kCLLocationAccuracyKilometer;
            [_manager startUpdatingLocation];
        }
    }
}

-(void)stop{
    [_manager stopUpdatingLocation];
    [_manager stopMonitoringSignificantLocationChanges];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //the most recent location update is at the end of the array.
    CLLocation *location = (CLLocation *)[locations lastObject];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:location.coordinate.latitude],@"latitude",[NSNumber numberWithDouble:location.coordinate.longitude],@"longitude", nil];
    [[NSUserDefaults standardUserDefaults] setObject:dictionary forKey:@"userLocation"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    if ([error domain] == kCLErrorDomain) {
        
        // We handle CoreLocation-related errors here
        switch ([error code]) {
                // "Don't Allow" on two successive app launches is the same as saying "never allow". The user
                // can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
            case kCLErrorDenied:{
                NSLog(@"fail to locate user: permission denied");
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kLocationServiceDisabledAlertTitle message:kLocationServiceDisabledAlertMessage delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
//                [alert show];
                
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
