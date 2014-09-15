//
//  LifestyleObject+Utilities.m
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "LifestyleObject+Utilities.h"
#import <Parse/Parse.h>
@implementation LifestyleObject (Utilities)
-(void)populateFromObject:(PFObject *)object{
    self.objectId = object.objectId;
    self.createdAt = object.createdAt;
    self.updatedAt = object.updatedAt;
    if(object[@"content"]){
        self.content = object[@"content"];
    }
    if (object[@"address"]) {
        self.address = object[@"address"];
    }
    if (object[@"category"]) {
        self.category = object[@"category"];
    }
    
    if (object[@"introduction"]) {
        self.introduction = object[@"introduction"];
    }
    
    if (object[@"name"]) {
        self.name = object[@"name"];
    }
    
    if (object[@"phone"]) {
        self.phone = object[@"phone"];
    }
    
    if (object[@"latitude"]) {
        self.latitude = object[@"latitude"];
    }
    
    if (object[@"longitude"]) {
        self.longitude = object[@"longitude"];
    }
}

@end
