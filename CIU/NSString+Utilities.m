//
//  NSString+Utilities.m
//  CIU
//
//  Created by Huang, Sihang on 9/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)

+(NSString *)generateUniqueId
{
    static NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *uid = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0U; i < 20; i++) {
        u_int32_t r = arc4random() % 62;
        unichar c = [alphabet characterAtIndex:r];
        [uid appendFormat:@"%C", c];
    }
    return uid;
}

- (BOOL)containsURL
{
    NSError *error;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    if (!error) {
        NSTextCheckingResult *result = [detector firstMatchInString:self options:NSMatchingReportCompletion range:NSMakeRange(0, self.length)];
        
        if (result) {
            return YES;
        }
    }
    
    return NO;
}

@end
