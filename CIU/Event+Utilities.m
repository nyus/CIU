//
//  Event+Utilities.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Event+Utilities.h"
#import <Parse/Parse.h>
@implementation Event (Utilities)
-(void)populateFromParseojbect:(PFObject *)object{
    self.createdAt = object.createdAt;
    self.updatedAt = object.updatedAt;
    self.objectId = object.objectId;
    if (object[@"eventName"]) {
        self.eventName = object[@"eventName"];
    }
    if (object[@"eventDate"]) {
        self.eventDate = object[@"eventDate"];
    }
    if (object[@"eventLocation"]) {
        self.eventLocation = object[@"eventLocation"];
    }
    if (object[@"eventContent"]) {
        self.eventContent = object[@"eventContent"];
    }
    if (object[@"senderUsername"]) {
        self.senderUsername = object[@"senderUsername"];
    }
    if (object[@"senderFirstName"]) {
        self.senderFirstName = object[@"senderFirstName"];
    }
    if (object[@"senderLastName"]) {
        self.senderLastName = object[@"senderLastName"];
    }
    if (object[@"latitude"]) {
        self.latitude = object[@"latitude"];
    }
    if (object[@"longitude"]) {
        self.longitude = object[@"longitude"];
    }
    if (object[@"isBadConteng"]) {
        self.isBadContent = object[@"isBadConteng"];
    }
}
@end
