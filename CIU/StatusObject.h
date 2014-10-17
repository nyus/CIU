//
//  StatusObject.h
//  CIU
//
//  Created by Sihang Huang on 10/17/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface StatusObject : NSManagedObject

@property (nonatomic, retain) NSNumber * anonymous;
@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * photoCount;
@property (nonatomic, retain) NSString * photoID;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * posterUsername;
@property (nonatomic, retain) NSNumber * statusCellHeight;
@property (nonatomic, retain) NSString * posterFirstName;
@property (nonatomic, retain) NSString * posterLastName;

@end
