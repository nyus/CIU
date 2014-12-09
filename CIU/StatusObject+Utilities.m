//
//  StatusObject+Utilities.m
//  CIU
//
//  Created by Sihang on 12/7/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "StatusObject+Utilities.h"
@class PFObject;
@implementation StatusObject (Utilities)

-(void)populateFromParseojbect:(PFObject *)object{
    self.createdAt = object.createdAt;
//    self.updatedAt = object.updatedAt;
    self.objectId = object.objectId;
    self.message = object[@"message"];
    self.picture = object[@"picture"];
    self.latitude = object[@"latitude"];
    self.longitude = object[@"longitude"];
    self.posterUsername = object[@"posterUsername"];
    self.posterFirstName = object[@"posterFirstName"];
    self.posterLastName = object[@"posterLastName"];
    self.likeCount = object[@"likeCount"];
    self.commentCount = object[@"commentCount"];
    self.photoCount = object[@"photoCount"];
    self.photoID = object[@"photoID"];
    self.anonymous = object[@"anonymous"];
    self.isBadContent = object[@"isBadContent"];
}


@end
