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
@property (nonatomic, strong) NSDate *greatestObjectDate;
@property (nonatomic, strong) NSDate *leastObjectDate;
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

//- (void)fetchLocalDataWithEntityName:(NSString *)entityName
//                          fetchLimit:(NSUInteger)fetchLimit
//                         fetchRadius:(CGFloat)fetchRadius
//                    greaterOrEqualTo:(NSDate *)greaterDate
//                     lesserOrEqualTo:(NSDate *)lesserDate;
#warning
- (void)fetchLocalDataWithEntityName:(NSString *)entityName
                          fetchLimit:(NSUInteger)fetchLimit
                         fetchRadius:(CGFloat)fetchRadius
                    greaterOrEqualTo:(NSDate *)greaterDate
                     lesserOrEqualTo:(NSDate *)lesserDate
                          predicates:(NSArray *)predicates;

-(void)fetchServerDataWithParseClassName:(NSString *)parseClassName
                              fetchLimit:(NSUInteger)fetchLimit
                             fetchRadius:(CGFloat)fetchRadius
                        greaterOrEqualTo:(NSDate *)greaterDate
                         lesserOrEqualTo:(NSDate *)lesserDate;

- (void)setupServerQueryWithClassName:(NSString *)className
                           fetchLimit:(NSUInteger)fetchLimit
                          fetchRadius:(CGFloat)fetchRadius
                     greaterOrEqualTo:(NSDate *)greaterDate
                      lesserOrEqualTo:(NSDate *)lesserDate;

-(void)populateManagedObject:(NSManagedObject *)managedObject
             fromParseObject:(PFObject *)object;

- (NSArray *)objectIdsToExclude;

- (NSPredicate *)dateRnagePredicateWithgreaterOrEqualTo:(NSDate *)greaterDate
                                        lesserOrEqualTo:(NSDate *)lesserDate;

- (NSPredicate *)geoBoundPredicateWithFetchRadius:(CGFloat)fetchRadius;

- (NSPredicate *)badLocalContentPredicate;

- (NSPredicate *)badContentPredicate;

@end
