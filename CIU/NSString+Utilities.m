//
//  NSString+Utilities.m
//  CIU
//
//  Created by Huang, Jason on 9/12/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "NSString+Utilities.h"

@implementation NSString (Utilities)
+(NSString *)generateUniqueId{
    static NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *uid = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0U; i < 20; i++) {
        u_int32_t r = arc4random() % 62;
        unichar c = [alphabet characterAtIndex:r];
        [uid appendFormat:@"%C", c];
    }
    return uid;
}
@end
