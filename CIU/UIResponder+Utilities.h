//
//  UIResponder+Utilities.h
//  DaDa
//
//  Created by Sihang on 2/14/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFUser;

@interface UIResponder (Utilities)

- (void)storeUserOnInstallation:(PFUser *)user;
- (void)storeUserOnInstallation:(PFUser *)user completion:(void(^)(BOOL succeeded, NSError *error))completion;

@end
