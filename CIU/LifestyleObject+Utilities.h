//
//  LifestyleObject+Utilities.h
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "LifestyleObject.h"
@class PFObject;
@interface LifestyleObject (Utilities)
-(void)populateFromObject:(PFObject *)object;
@end
