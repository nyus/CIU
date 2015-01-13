//
//  LifestyleTableViewController.m
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleTableViewController.h"
#import "LifestyleCategory.h"
#import "LifestyleCategory+Utilities.h"
#import "Query.h"
#import "Helper.h"
#import "LifestyleDetailViewController.h"
#import "LifestyleTableViewCell.h"

static NSString *LifestyleCategoryName = @"LifestyleCategory";
@interface LifestyleTableViewController ()
@property (nonatomic, strong) NSMutableDictionary *queries;
@end

@implementation LifestyleTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.tableFooterView = [[UIView alloc] init];
    
    UIEdgeInsets inset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.tableView.contentInset = inset;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //    self.queries= [NSMutableDictionary dictionary];
    
    PFUser *user = [PFUser currentUser];
    if (!(user || [PFFacebookUtils isLinkedWithUser:[PFUser currentUser]])) {
        [self showLoginViewController];
    }
    
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // handle successful response
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
            
            [self showLoginViewController];
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
    
    [self pullDataFromLocal];
    
    if ([Reachability canReachInternet]) {
        [self pullDataFromServer];
    }
}

-(void)showLoginViewController{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
    [self presentViewController:vc animated:NO completion:nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //we add a right bar button item on statusViewcOntroller. since all the tabs are sharing the same navigation bar, here we take out the right item
    //add right bar item(compose)
    UITabBarController *tab=self.navigationController.viewControllers[0];
    tab.navigationItem.rightBarButtonItem = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshControlTriggered:(UIRefreshControl *)sender{
    [self pullDataFromServer];
}

#pragma mark - Override

-(void)pullDataFromLocal{
    
    if (!self.dataSource) {
        self.dataSource = [NSMutableArray array];
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:LifestyleCategoryName];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"importance"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count!=0) {
        [self.dataSource addObjectsFromArray:fetchedObjects];
        [self.tableView reloadData];
    }
}

-(void)pullDataFromServer{
    PFQuery *query = [[PFQuery alloc] initWithClassName:LifestyleCategoryName];
    [query orderByAscending:@"importance"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count>0) {
            
            if (!self.dataSource) {
                self.dataSource = [NSMutableArray array];
            }
            
            NSMutableArray *indexpathArray = [NSMutableArray array];
            int originalCount = (int)self.dataSource.count;
            __block int i = 0;
            for (PFObject *parseObject in objects) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    LifestyleCategory *category;
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.objectId MATCHES[cd] %@",parseObject.objectId];
                    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:LifestyleCategoryName];
                    request.predicate = predicate;
                    NSArray *array = [[[SharedDataManager sharedInstance] managedObjectContext] executeFetchRequest:request error:nil];
                    if (array.count==1) {
                        category = array[0];
                        [category populateFromParseojbect:parseObject];
                    } else {
                        category = [NSEntityDescription insertNewObjectForEntityForName:LifestyleCategoryName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                        [category populateFromParseojbect:parseObject];
                        [[SharedDataManager sharedInstance] saveContext];
                        [self.dataSource addObject:category];
                        NSIndexPath *path = [NSIndexPath indexPathForRow:i+originalCount inSection:0];
                        [indexpathArray addObject:path];
                        [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationFade];
                        i++;
                    }
                });
            }
            
//            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//            for (int i =0; i<self.dataSource.count; i++) {
//                LifestyleCategory *category = self.dataSource[i];
//                [dict setValue:[NSNumber numberWithInteger:i] forKey:category.objectId];
//            }
//            
//            for (int i =0; i<objects.count; i++) {
//                
//                
//                PFObject *parseObject = objects[i];
//                NSNumber *index = [dict valueForKey:parseObject.objectId];
//                if (index) {
//                    //update
//                    LifestyleCategory *category = self.dataSource[index.intValue];
//                    //only if we need to update
//                    if ([category.updatedAt compare:parseObject.updatedAt] == NSOrderedAscending) {
//                        [category populateFromParseojbect:parseObject];
//                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
//                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
//                    }
//                }else{
//                    //insert
//                    LifestyleCategory *category = [NSEntityDescription insertNewObjectForEntityForName:LifestyleCategoryName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
//                    [category populateFromParseojbect:parseObject];
//                    [self.dataSource addObject:category];
//                    NSIndexPath *path = [NSIndexPath indexPathForRow:self.dataSource.count-1 inSection:0];
//                    [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
//                    [[SharedDataManager sharedInstance] saveContext];
//                }
//            }
        }
    }];
}

//-(void)loadRemoteDataForVisibleCells{
//    for (UITableViewCell *cell in self.tableView.visibleCells) {
//        
//        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//        LifestyleCategory *category = self.dataSource[indexPath.row];
//        NSString *imageName = [LifestyleCategoryName stringByAppendingString:category.name];
//        
//        if (cell.imageView.image != nil || [Helper isLocalImageExist:imageName isHighRes:NO]) {
//            continue;
//        }
//        
//
//        Query *query = [[Query alloc] init];
//        __block UITableViewCell *weakCell = cell;
//        [query getServerImageWithName:imageName isHighRes:NO completion:^(NSError *error, UIImage *image) {
//            if (!error) {
//                weakCell.imageView.image = image;
//                
//            }else{
//                weakCell.imageView.image = nil;
//            }
//        }];
//        [self.queries setObject:query forKey:indexPath];
//    }
//}
//
//-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{
//    Query *query = [self.queries objectForKey:indexPath];
//    if (query) {
//        [query cancelRequest];
//    }
//    [self.queries removeObjectForKey:indexPath];
//}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (NSString*)imageNameOfCategory:(LifestyleCategory*)category
{
    if([category.name isEqualToString:@"Restaurant"]){
        return @"2retserant";
    }else if([category.name isEqualToString:@"Supermarket"]){
        return @"2markets";
    }else if([category.name isEqualToString:@"Jobs"]){
        return @"2job";
    }else{
        return @"2Sale";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *categoryCell = @"categoryCell";
    LifestyleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:categoryCell forIndexPath:indexPath];
    
    LifestyleCategory *category = self.dataSource[indexPath.row];
    
    NSString *imageName = [self imageNameOfCategory:category];
    cell.cellImageView.image = [UIImage imageNamed:imageName];
    
    cell.label.text = category.name;
    return cell;
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"toDetailA"]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        LifestyleCategory *category = self.dataSource[indexPath.row];
        LifestyleDetailViewController *vc = (LifestyleDetailViewController *)segue.destinationViewController;
        vc.categoryName = category.name;
    }
}

@end
