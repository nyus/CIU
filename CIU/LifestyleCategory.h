//
//  LifestyleCategory.h
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface LifestyleCategory : NSManagedObject

@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSNumber * importance;

@end
