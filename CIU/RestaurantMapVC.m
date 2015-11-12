//
//  RestaurantMapVC.m
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "RestaurantMapVC.h"

static CGFloat const kServerFetchCount = 50.0;
static CGFloat const kLocalFetchCount = 50.0;
static NSString *const kEntityName = @"LifestyleObject";
static NSString *const kRestaurantDataRadiusKey = @"kRestaurantDataRadiusKey";
static NSString *const kCategoryName = @"Restaurant";

@interface RestaurantMapVC ()

@end

@implementation RestaurantMapVC

- (NSString *)serverDataParseClassName
{
    return DDRestaurantParseClassName;
}

- (NSString *)localDataEntityName
{
    return kEntityName;
}

- (float)serverFetchCount
{
    return kServerFetchCount;
}

- (float)localFetchCount
{
    return kLocalFetchCount;
}

- (NSString *)keyForLocalDataSortDescriptor
{
    return DDNameKey;
}

- (BOOL)orderLocalDataInAscending
{
    return YES;
}

- (NSString *)lifestyleObjectCategory
{
    return kCategoryName;
}

- (void)handleRedoSearchButtonTapped
{
    [[GAnalyticsManager shareManager] trackUIAction:@"buttonPress" label:@"Restaurant-Redo search in map" value:nil];
    [Flurry logEvent:@"Restaurant-Redo search in map"];
    
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithRegion:self.mapView.region];
    }
}

@end
