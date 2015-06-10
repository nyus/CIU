//
//  FPLogger.m
//  FastPost
//
//  Created by Sihang Huang on 3/30/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//


#import <MessageUI/MessageUI.h>
#import <Parse/Parse.h>

static NSString *_string;

@implementation FPLogger

+ (void)record:(NSString *)log
{
    PFObject *debugLog = [[PFObject alloc] initWithClassName:@"Log"];
    [debugLog setObject:log forKey:@"Log"];
    if ([PFUser currentUser]) {
        [debugLog setObject:[PFUser currentUser].username forKey:DDUserNameKey];
    }
    [debugLog setObject:@(CFAbsoluteTimeGetCurrent()) forKey:@"absoluteTime"];
    [debugLog saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!succeeded) {
            [debugLog saveEventually];
        }
    }];
}

//+(void)record:(NSString *)log{
//    if (_string==nil) {
//        _string = [[NSUserDefaults standardUserDefaults] objectForKey:@"diagnosis"];
//        if (!_string) {
//            _string = @"";
//        }
//    }
//    
//    _string = [_string stringByAppendingFormat:@"%@\n",log];
//    [[NSUserDefaults standardUserDefaults] setObject:_string forKey:@"diagnosis"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//}

+(void)sendReport{
    
    if(_string){
        PFObject *debugLog = [[PFObject alloc] initWithClassName:@"Log"];
        [debugLog setObject:_string forKey:@"Log"];
        [debugLog setObject:[PFUser currentUser].username forKey:DDUserNameKey];
        [debugLog saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!succeeded) {
                [debugLog saveEventually];
            }
        }];
        
        //clear for the next report
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"diagnosis"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
}

@end
