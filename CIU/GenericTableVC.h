//
//  GenericTableViewController.h
//  CIU
//
//  Created by Huang, Sihang on 8/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "SharedDataManager.h"

@interface GenericTableVC : UITableViewController
{
    @protected
    NSUInteger _localDataCount;
    NSUInteger _serverDataCount;
}

@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) PFQuery *fetchQuery;
@property (nonatomic, assign) BOOL isInternetPresentOnLaunch;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@property (nonatomic, strong) id greaterValue;
@property (nonatomic, strong) id lesserValue;
@property (nonatomic, copy) NSString *localDataEntityName;
@property (nonatomic, copy) NSString *serverDataParseClassName;
@property (nonatomic, assign) float dataFetchRadius;
@property (nonatomic, assign) float serverFetchCount;
@property (nonatomic, assign) float localFetchCount;

-(void)loadRemoteDataForVisibleCells;

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath;

-(void)cancelNetworkRequestForCell:(UITableViewCell *)cell
                       atIndexPath:(NSIndexPath *)indexPath;

-(void)addPullDownRefreshControl;

-(void)addInfiniteRefreshControl;

- (void)handlePullDownToRefresh;

- (void)handleInfiniteScroll;

-(void)locationManager:(CLLocationManager *)manager
     didUpdateLocation:(CLLocation *)location;

- (NSString *)keyForLocalDataSortDescriptor;

- (BOOL)orderLocalDataInAscending;

- (NSFetchRequest *)localDataFetchRequestWithEntityName:(NSString *)entityName
                                             fetchLimit:(NSUInteger)fetchLimit
                                             predicates:(NSArray *)predicates;

- (void)fetchLocalDataWithEntityName:(NSString *)entityName
                          fetchLimit:(NSUInteger)fetchLimit
                          predicates:(NSArray *)predicates;

-(void)fetchServerDataWithParseClassName:(NSString *)parseClassName
                              fetchLimit:(NSUInteger)fetchLimit
                             fetchRadius:(CGFloat)fetchRadius
                        greaterOrEqualTo:(id)greaterValue
                         lesserOrEqualTo:(id)lesserValue;

- (void)setupServerQueryWithClassName:(NSString *)className
                           fetchLimit:(NSUInteger)fetchLimit
                          fetchRadius:(CGFloat)fetchRadius
                     greaterOrEqualTo:(id)greaterValue
                      lesserOrEqualTo:(id)lesserValue;

-(void)populateManagedObject:(NSManagedObject *)managedObject
             fromParseObject:(PFObject *)object;

- (id)valueToCompareAgainst:(id)object;

- (NSArray *)objectIdsToExclude;

- (NSPredicate *)dateRnagePredicateWithgreaterOrEqualTo:(id)greaterValue
                                        lesserOrEqualTo:(id)lesserValue;

- (NSPredicate *)geoBoundPredicateWithFetchRadius:(CGFloat)fetchRadius;

- (NSPredicate *)stickyPostPredicate;

- (NSPredicate *)badLocalContentPredicate;

- (NSPredicate *)badContentPredicate;

@end
