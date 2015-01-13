//
//  GAnalyticsManager.m
//  CIU
//
//  Created by Sihang on 1/12/15.
//  Copyright (c) 2015 Huang, Jason. All rights reserved.
//

#import "GAnalyticsManager.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

static GAnalyticsManager *_manager;

@implementation GAnalyticsManager

+ (GAnalyticsManager *)shareManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [GAnalyticsManager new];
    });
    
    return _manager;
}

- (void)trackScreen:(NSString *)screenName
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)trackUIAction:(NSString *)actionName label:(NSString *)eventLabel value:(NSNumber *)eventValue
{
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:actionName  // Event action (required)
                                                           label:eventLabel          // Event label
                                                           value:eventValue] build]];    // Event value
}
@end
