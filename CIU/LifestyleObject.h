//
//  LifestyleObject.h
//  CIU
//
//  Created by Sihang on 8/24/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LifestyleObject : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * introduction;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) id phone;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * website;
@property (nonatomic, retain) id hours;

@end
