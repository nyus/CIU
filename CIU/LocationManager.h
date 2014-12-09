//
//  LocationManager.h
//  CIU
//
//  Created by Sihang on 9/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface LocationManager : NSObject
//@property (strong,nonatomic) id delegate;
+(CLLocationManager *)sharedInstance;
-(void)start;
-(void)stop;
-(CLAuthorizationStatus)authorizationStatus;
@end
