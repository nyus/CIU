//
//  PFFile+Utilities.m
//  DaDa
//
//  Created by Sihang on 8/21/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "PFFile+Utilities.h"
#import "Helper.h"

@implementation PFFile (Utilities)

- (void)fetchImageWithCompletionBlock:(void (^)(BOOL, NSData *))completion
{
    [self getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Failed to down load file: %@", self);
            completion(NO, nil);
        } else {
            completion(YES, data);
        }
    }];
}

@end
