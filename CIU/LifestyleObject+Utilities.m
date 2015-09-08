//
//  LifestyleObject+Utilities.m
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleObject+Utilities.h"
#import <Parse/Parse.h>
static NSString *const kContentKey = @"content";
static NSString *const kAddressKey = @"address";
static NSString *const kStreetKey = @"street";
static NSString *const kCityKey = @"city";
static NSString *const kStateKey = @"state";
static NSString *const kZipKey = @"zip";
static NSString *const kCategoryKey = @"category";
static NSString *const kIntroductionKey = @"introduction";
static NSString *const kNameKey = @"name";
static NSString *const kPhonekey = @"phone";
static NSString *const kLatitudeKey = @"latitude";
static NSString *const kLongitudeKey = @"longitude";
static NSString *const kIsBadContent = @"isBadContent";

@implementation LifestyleObject (Utilities)
-(void)populateFromParseObject:(PFObject *)object{
    self.objectId = object.objectId;
    self.createdAt = object.createdAt;
    self.updatedAt = object.updatedAt;
    
    if(object[kContentKey]){
        self.content = object[kContentKey];
    }
    
    if (object[kAddressKey]) {
        self.address = object[kAddressKey];
    } else {
        NSMutableString *address = [NSMutableString new];
        if (object[kStreetKey]) {
            [address appendString:object[kStreetKey]];
        }
        if (object[kCityKey]) {
            [address appendString:@", "];
            [address appendString:object[kCityKey]];
        }
        if (object[kStateKey]) {
            [address appendString:@", "];
            [address appendString:object[kStateKey]];
        }
        if (object[kZipKey]) {
            [address appendString:@", "];
            [address appendString:object[kZipKey]];
        }
        self.address = [address copy];
    }
    
    if (object[kCategoryKey]) {
        self.category = object[kCategoryKey];
    }
    
    if (object[kIntroductionKey]) {
        self.introduction = object[kIntroductionKey];
    }
    
    if (object[kNameKey]) {
        self.name = object[kNameKey];
    }
    
    if (object[kPhonekey]) {
        self.phone = object[kPhonekey];
    }
    
    if (object[kLatitudeKey]) {
        self.latitude = object[kLatitudeKey];
    }
    
    if (object[kLongitudeKey]) {
        self.longitude = object[kLongitudeKey];
    }
    
    if (object[kIsBadContent]) {
        self.isBadContent = object[kIsBadContent];
    }
    
    self.isBadContentLocal = @NO;
}

@end
