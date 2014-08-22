//
//  FPLogger.h
//  FastPost
//
//  Created by Sihang Huang on 3/30/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FPLogger : NSObject
+(void)record:(NSString *)log;
+(void)sendReport;
@end
