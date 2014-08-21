//
//  LifestyleCategory+Utilities.m
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "LifestyleCategory+Utilities.h"
#import <Parse/Parse.h>
@implementation LifestyleCategory (Utilities)
-(void)populateFromParseojbect:(PFObject *)parseObject{
    self.objectId = parseObject.objectId;
    self.createdAt = parseObject.createdAt;
    self.updatedAt = parseObject.updatedAt;
    self.name = parseObject[@"name"];
    self.iconURL = parseObject[@"iconURL"];
    self.importance = parseObject[@"importance"];
}
@end
