//
//  StatusObject+Utilities.h
//  CIU
//
//  Created by Sihang on 12/7/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "StatusObject.h"
#import <Parse/Parse.h>

@interface StatusObject (Utilities)
-(void)populateFromParseojbect:(PFObject *)object;
@end
