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

-(void)populateFromParseObject:(PFObject *)object{
    self.createdAt = object.createdAt;
//    self.updatedAt = object.updatedAt;
    self.objectId = object.objectId;
    
    if (object[DDMessageKey]) {
        self.message = object[DDMessageKey];
    }
    
    if (object[DDPictureKey]) {
        self.picture = object[DDPictureKey];
    }
    
    if (object[DDLatitudeKey]) {
        self.latitude = object[DDLatitudeKey];
    }
    
    if (object[DDLongitudeKey]) {
        self.longitude = object[DDLongitudeKey];
    }

    if (object[DDPosterUserNameKey]) {
        self.posterUsername = object[DDPosterUserNameKey];
    }
    
    if (object[DDPosterUserNameKey]) {
        self.posterUsername = object[DDPosterUserNameKey];
    }
    
    if (object[DDPosterFirstNameKey]) {
        self.posterFirstName = object[DDPosterFirstNameKey];
    }
    
    if (object[DDPosterLastNameKey]) {
        self.posterLastName = object[DDPosterLastNameKey];
    }
    
    if (object[DDLikeCountKey]) {
        self.likeCount = object[DDLikeCountKey];
    }

    if (object[DDCommentCountKey]) {
        self.commentCount = object[DDCommentCountKey];
    }
    
    if (object[DDPhotoCountKey]) {
        self.photoCount = object[DDPhotoCountKey];
    }

    if (object[DDPhotoIdKey]) {
        self.photoID = object[DDPhotoIdKey];
    }
    
    if (object[DDAnonymousKey]) {
        self.anonymous = object[DDAnonymousKey];
    }
    
    if (object[DDIsBadContentKey]) {
        self.isBadContent = object[DDIsBadContentKey];
    }
    
    if (object[DDIsStickyPostKey]) {
        self.isStickyPost = object[DDIsStickyPostKey];
    }
    
    self.isBadContentLocal = @NO;
}


@end
