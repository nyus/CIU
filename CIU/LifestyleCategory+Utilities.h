//
//  LifestyleCategory+Utilities.h
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleCategory.h"
@class PFObject;
@interface LifestyleCategory (Utilities)
-(void)populateFromParseojbect:(PFObject *)parseObject;
@end
