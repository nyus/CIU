//
//  AnalyticsManager.m
//  DaDa
//
//  Created by Sihang on 5/15/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "AnalyticsManager.h"
#import "GAnalyticsManager.h"
#import "Flurry.h"

static NSString *const kPublishEventName = @"Publish Event";
static NSString *const kLatitudeKey = @"Latitude";
static NSString *const kLongitudeKey = @"longitude";

@implementation AnalyticsManager

+ (void)logPublicEventWithLatitude:(NSNumber *)latitude longitude:(NSNumber *)longitude
{
    [[GAnalyticsManager shareManager] trackUIAction:kPublishEventName
                                              label:FSTRING(@"event location:%f %f",
                                                            latitude ? latitude.doubleValue : -1,
                                                            longitude ? longitude.doubleValue : -1)
                                              value:nil];
    [Flurry logEvent:kPublishEventName withParameters:@{kLatitudeKey: latitude ? latitude : @(-1),
                                                        kLongitudeKey: longitude ? longitude : @(-1)}];
}

@end
