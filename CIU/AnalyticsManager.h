//
//  AnalyticsManager.h
//  DaDa
//
//  Created by Sihang on 5/15/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnalyticsManager : NSObject

+ (void)logPublicEventWithLatitude:(NSNumber *)latitude longitude:(NSNumber *)longitude;

@end
