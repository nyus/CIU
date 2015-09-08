//
//  LifestyleObject+Utilities.h
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleObject.h"

@class PFObject;

@interface LifestyleObject (Utilities)

-(void)populateFromParseObject:(PFObject *)object;

@end
