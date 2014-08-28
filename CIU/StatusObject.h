//
//  StatusObject.h
//  CIU
//
//  Created by Huang, Jason on 8/28/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface StatusObject : NSManagedObject

@property (nonatomic, retain) NSString * avatar;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * message;
@property (nonatomic, retain) NSString * picture;
@property (nonatomic, retain) NSString * posterUsername;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSNumber * likeCount;
@property (nonatomic, retain) NSNumber * commentCount;
@property (nonatomic, retain) NSNumber * photoCount;

@end
