//
//  UIViewController+Utilities.m
//  DaDa
//
//  Created by Sihang Huang on 2/4/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "UIViewController+Utilities.h"
#import <Parse/Parse.h>
#import "UIAlertView+Blocks.h"

NSString *const kYesKey = @"Yes";
NSString *const kNoKey = @"No";

@implementation UIViewController (Utilities)

- (void)flagObjectForId:(NSString *)objectId parseClassName:(NSString *)parseClassName completion:(void(^)(BOOL succeeded, NSError *error))completion
{
    [UIAlertView showWithTitle:nil message:@"是否确认举报此条不良信息？" cancelButtonTitle:kNoKey otherButtonTitles:@[kYesKey] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:kYesKey]) {
            PFQuery *query = [PFQuery queryWithClassName:parseClassName];
            [query whereKey:@"objectId" equalTo:objectId];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                if (error) {
                    NSLog(@"get status object with id:%@ failed",object.objectId);
                } else {
                    [object setObject:@YES forKey:@"isBadContent"];
                    [object saveEventually:^(BOOL succeeded, NSError *error) {
                        completion (succeeded, error);
                    }];
                    
                    PFObject *audit = [PFObject objectWithClassName:@"Audit"];
                    audit[@"auditObjectId"] = object.objectId;
                    [audit saveEventually];
                }
            }];
        }
    }];
}

-(void)storeUserOnInstallation:(PFUser *)user
{
    // Store PFUser on PFInstallation
    if ([PFInstallation currentInstallation]) {
        PFInstallation *installation = [PFInstallation currentInstallation];
        installation[DDUserKey] = user;
        if (user.username) {
            installation[DDUserNameKey] = user.username;
        }
        [installation saveEventually];
    }
}
@end
