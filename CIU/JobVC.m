//
//  JobVC.m
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "JobVC.h"
#import "JobTradeTableViewCell.h"
#import "Helper.h"
#import "LifestyleObject+Utilities.h"
#import "ComposeJobOrTradeVC.h"

static CGFloat const kServerFetchCount = 50.0;
static CGFloat const kLocalFetchCount = 50.0;
static NSString *const kEntityName = @"LifestyleObject";
static NSString *const kJobAndTradeCellReuseID = @"kJobAndTradeCellReuseID";
static NSString *const kCategoryName = @"Jobs";

@interface JobVC () <JobTradeTableViewCellDelegate>

@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation JobVC

#pragma mark - View life cycle

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        // So that there is navigation back button
        
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Jobs";
    self.navigationItem.leftBarButtonItem.accessibilityLabel = @"Back";
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItem = rightItem;
    [self.tableView registerClass:[JobTradeTableViewCell class] forCellReuseIdentifier:kJobAndTradeCellReuseID];
    
    [self addInfiniteRefreshControl];
    [self addPullDownRefreshControl];
    
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:nil];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius]]];
    }
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(handleBackButton:)];
    self.navigationItem.leftBarButtonItem = back;
}

- (void)handleBackButton:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[PFUser currentUser] fetchInBackground];
    [Flurry logEvent:@"View jobs" timed:YES];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.fetchQuery cancel];
    [Flurry endTimedEvent:@"View jobs" withParameters:nil];
}

#pragma mark - Action

-(void)addButtonTapped:(UIBarButtonItem *)sender
{
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *vc = (UINavigationController *)[storyBoard instantiateViewControllerWithIdentifier:@"compose"];
    ComposeJobOrTradeVC *compose = (ComposeJobOrTradeVC *)vc.topViewController;
    compose.categoryType = DDCategoryTypeJob;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Helper

- (NSPredicate *)jobCategoryTypePredicate
{
    return [NSPredicate predicateWithFormat:@"self.category MATCHES[cd] %@", kCategoryName];
}

#pragma mark - Override

- (NSString *)serverDataParseClassName
{
    return DDJobParseClassName;
}

- (NSString *)localDataEntityName
{
    return kEntityName;
}

- (float)dataFetchRadius
{
    return 0;
}

- (float)serverFetchCount
{
    return kServerFetchCount;
}

- (float)localFetchCount
{
    return kLocalFetchCount;
}

- (NSString *)keyForLocalDataSortDescriptor
{
    return DDCreatedAtKey;
}

- (BOOL)orderLocalDataInAscending
{
    return NO;
}

- (void)handlePullDownToRefresh
{
    if (!self.isInternetPresentOnLaunch) {
        [self fetchLocalDataWithEntityName:self.localDataEntityName
                                fetchLimit:self.localFetchCount
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self jobCategoryTypePredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius],
                                             [self dateRnagePredicateWithgreaterOrEqualTo:self.greaterValue
                                                                          lesserOrEqualTo:nil]]];
    } else {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:self.greaterValue
                                lesserOrEqualTo:nil];
    }
}

- (void)handleInfiniteScroll
{
    if (self.isInternetPresentOnLaunch) {
        [self fetchServerDataWithParseClassName:self.serverDataParseClassName
                                     fetchLimit:self.serverFetchCount
                                    fetchRadius:self.dataFetchRadius
                               greaterOrEqualTo:nil
                                lesserOrEqualTo:self.lesserValue];
    } else {
        [self fetchLocalDataWithEntityName:kEntityName
                                fetchLimit:self.localFetchCount
                                predicates:@[[self badContentPredicate],
                                             [self badLocalContentPredicate],
                                             [self jobCategoryTypePredicate],
                                             [self geoBoundPredicateWithFetchRadius:self.dataFetchRadius],
                                             [self dateRnagePredicateWithgreaterOrEqualTo:nil
                                                                          lesserOrEqualTo:self.lesserValue]]];
    }
}

- (id)valueToCompareAgainst:(id)object
{
    id valueToCompare;
    
    if ([object isKindOfClass:[PFObject class]]) {
        valueToCompare = ((PFObject *)object).createdAt;
    } else if ([object isKindOfClass:[NSManagedObject class]]) {
        valueToCompare = [object createdAt];
    }
    
    return valueToCompare;
}

- (NSFetchRequest *)localDataFetchRequestWithEntityName:(NSString *)entityName
                                             fetchLimit:(NSUInteger)fetchLimit
                                             predicates:(NSArray *)predicates
{
    NSFetchRequest *fetchRequest = [super localDataFetchRequestWithEntityName:entityName
                                                                   fetchLimit:fetchLimit
                                                                   predicates:predicates];
    
    return fetchRequest;
}

- (void)setupServerQueryWithClassName:(NSString *)className
                           fetchLimit:(NSUInteger)fetchLimit
                          fetchRadius:(CGFloat)fetchRadius
                     greaterOrEqualTo:(id)greaterValue
                      lesserOrEqualTo:(id)lesserValue
{
    if (self.fetchQuery) {
        [self.fetchQuery cancel];
        self.fetchQuery = nil;
    }
    
    self.fetchQuery = [[PFQuery alloc] initWithClassName:className];
    [self.fetchQuery orderByDescending:DDCreatedAtKey];
    [self.fetchQuery whereKey:DDObjectIdKey
               notContainedIn:[Helper flaggedLifeStyleObjectIds]];
    
    if (greaterValue) {
        [self.fetchQuery whereKey:DDCreatedAtKey
                      greaterThan:greaterValue];
    }
    
    if (lesserValue) {
        [self.fetchQuery whereKey:DDCreatedAtKey
                         lessThan:lesserValue];
    }
    
    self.fetchQuery.limit = fetchLimit;
}

- (void)populateManagedObject:(NSManagedObject *)managedObject
              fromParseObject:(PFObject *)object
{
    [((LifestyleObject *)managedObject) populateFromParseObject:object];
}

#pragma mark - UITableView Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LifestyleObject *object = self.dataSource[indexPath.row];
    
    JobTradeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kJobAndTradeCellReuseID forIndexPath:indexPath];
    cell.delegate = self;
    cell.contentTextView.text = nil;
    cell.contentTextView.text = object.content;
    cell.flagButton.enabled = !object.isBadContent.boolValue;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    LifestyleObject *object = self.dataSource[indexPath.row];
    
    return [JobTradeTableViewCell heightForCellWithContentString:object.content
                                                       cellWidth:CGRectGetWidth(tableView.frame)];
}

#pragma mark - JobTradeTableViewCellDelegate

- (void)flagBadContentButtonTappedOnCell:(JobTradeTableViewCell *)cell{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __block LifestyleObject *lifeObject = self.dataSource[indexPath.row];
    
    [self showReportAlertWithBlock:^(BOOL yesButtonTapped) {
        if (yesButtonTapped) {
            [Helper createAuditWithObjectId:lifeObject.objectId category:lifeObject.category];
            [Helper flagLifeStyleObject:lifeObject];
            
            lifeObject.isBadContentLocal = @YES;
            [[SharedDataManager sharedInstance] saveContext];
            
            [self.dataSource removeObject:lifeObject];
            [self.tableView reloadData];
        }
    }];
}

@end
