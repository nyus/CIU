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
    self.eventName = object[@"eventName"];
    self.eventDate = object[@"eventDate"];
    self.eventLocation = object[@"eventLocation"];
    self.eventContent = object[@"eventContent"];
    self.senderUsername = object[@"senderUsername"];
    self.senderFirstName = object[@"senderFirstName"];
    self.senderLastName = object[@"senderLastName"];
    self.latitude = object[@"latitude"];
    self.longitude = object[@"longitude"];
}
@end
