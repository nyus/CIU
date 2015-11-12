//
//  Event+Utilities.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Event+Utilities.h"
#import <Parse/Parse.h>

@implementation Event (Utilities)
-(void)populateFromParseObject:(PFObject *)object{
    self.createdAt = object.createdAt;
    self.updatedAt = object.updatedAt;
    self.objectId = object.objectId;
    
    if (object[DDEventNameKey]) {
        self.eventName = object[DDEventNameKey];
    }
    
    if (object[DDEventDateKey]) {
        self.eventDate = object[DDEventDateKey];
    }
    
    if (object[DDEventLocationKey]) {
        self.eventLocation = object[DDEventLocationKey];
    }
    
    if (object[DDEventContentKey]) {
        self.eventContent = object[DDEventContentKey];
    }
    
    if (object[DDSenderUserNameKey]) {
        self.senderUsername = object[DDSenderUserNameKey];
    }
    
    if (object[DDSenderFirstNameKey]) {
        self.senderFirstName = object[DDSenderFirstNameKey];
    }
    
    if (object[DDSenderLastNameKey]) {
        self.senderLastName = object[DDSenderLastNameKey];
    }
    
    if (object[DDLatitudeKey]) {
        self.latitude = object[DDLatitudeKey];
    }
    
    if (object[DDLongitudeKey]) {
        self.longitude = object[DDLongitudeKey];
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
