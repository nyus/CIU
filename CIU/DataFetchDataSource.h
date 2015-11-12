//
//  DataFetchDataSource.h
//  DaDa
//
//  Created by Sihang on 10/3/15.
//  Copyright © 2015 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DataFetchDataSource <NSObject>

- (NSString *)serverDataParseClassName;

- (NSString *)localDataEntityName;

- (float)dataFetchRadius;

- (float)serverFetchCount;

- (float)localFetchCount;

- (NSString *)keyForLocalDataSortDescriptor;

- (BOOL)orderLocalDataInAscending;

- (NSArray *)objectIdsToExclude;

- (NSSortDescriptor *)sortedDescriptorForServerData;

@end
