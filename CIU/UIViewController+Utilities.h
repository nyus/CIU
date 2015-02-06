//
//  UIViewController+Utilities.h
//  DaDa
//
//  Created by Sihang Huang on 2/4/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFUser;

@interface UIViewController (Utilities)

- (void)flagObjectForId:(NSString *)objectId parseClassName:(NSString *)parseClassName completion:(void(^)(BOOL succeeded, NSError *error))completion;
- (void)storeUserOnInstallation:(PFUser *)user;
@end
