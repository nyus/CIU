//
//  Event.h
//  CIU
//
//  Created by Sihang on 9/7/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * eventContent;
@property (nonatomic, retain) NSDate * eventDate;
@property (nonatomic, retain) NSString * eventName;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * senderFirstName;
@property (nonatomic, retain) NSString * senderLastName;
@property (nonatomic, retain) NSString * senderUsername;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * cellHeight;
@property (nonatomic, retain) NSString * eventLocation;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;

@end
