//
//  UIResponder+Utilities.m
//  DaDa
//
//  Created by Sihang on 2/14/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "UIResponder+Utilities.h"
#import <Parse/Parse.h>

@implementation UIResponder (Utilities)

-(void)storeUserOnInstallation:(PFUser *)user
{
    if (!user) {
        return;
    }
    
    // Store PFUser on PFInstallation
    if ([PFInstallation currentInstallation]) {
        [self setupInstallationWithUser:user];
        [[PFInstallation currentInstallation] saveInBackground];
    }
}

-(void)storeUserOnInstallation:(PFUser *)user completion:(void(^)(BOOL succeeded, NSError *error))completion
{
    if (!user) {
        NSString *domain = @"com.sihangHuang.DaDa.ErrorDomain";
        NSString *desc = NSLocalizedString(@"Unabled to store nil PFUser on PFInstallation.", @"");
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        NSError *error = [NSError errorWithDomain:domain
                                             code:-101
                                         userInfo:userInfo];
        completion (NO, error);
        return;
    }
    
    // Store PFUser on PFInstallation
    if ([PFInstallation currentInstallation]) {
        [self setupInstallationWithUser:user];
        [[PFInstallation currentInstallation] saveEventually:^(BOOL succeeded, NSError *error) {
            completion (succeeded, error);
        }];
    }
}

- (void)setupInstallationWithUser:(PFUser *)user
{
    [[PFInstallation currentInstallation] setObject:user forKey:DDUserKey];
    if (user.username) {
        [[PFInstallation currentInstallation] setObject:user.username forKey:DDUserNameKey];
    }
}

@end
