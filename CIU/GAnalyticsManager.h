//
//  GAnalyticsManager.h
//  CIU
//
//  Created by Sihang on 1/12/15.
//  Copyright (c) 2015 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GAnalyticsManager : NSObject
+ (GAnalyticsManager *)shareManager;
- (void)trackScreen:(NSString *)screenName;
- (void)trackUIAction:(NSString *)actionName label:(NSString *)eventLabel value:(NSNumber *)eventValue;
@end
