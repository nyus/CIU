//
//  SharedDataManager.h
//  HomeBuyingApp
//
//  Created by Dickman, Mike on 4/18/13.
//  Copyright (c) 2013 Quicken Loans. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SharedDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+(SharedDataManager*)sharedInstance;
-(NSManagedObjectContext*)managedObjectContext;
-(void)saveContext;

@end
