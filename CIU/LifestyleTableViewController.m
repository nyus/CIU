//
//  LifestyleTableViewController.m
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "LifestyleTableViewController.h"
#import "LifestyleCategory.h"
#import "LifestyleCategory+Utilities.h"
#import "Query.h"
#import "Helper.h"
static NSString *LifestyleCategoryName = @"LifestyleCategory";
@interface LifestyleTableViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) NSMutableDictionary *queries;
@end

@implementation LifestyleTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.queries= [NSMutableDictionary dictionary];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (int i =0; i<self.dataSource.count; i++) {
                LifestyleCategory *category = self.dataSource[i];
                [dict setValue:[NSNumber numberWithInteger:i] forKey:category.objectId];
            }
            
            for (int i =0; i<objects.count; i++) {
                PFObject *parseObject = objects[i];
                NSNumber *index = [dict valueForKey:parseObject.objectId];
                if (index) {
                    //update
                    LifestyleCategory *category = self.dataSource[index.intValue];
                    //only if we need to update
                    if ([category.updatedAt compare:parseObject.updatedAt] == NSOrderedAscending) {
                        [category populateFromParseojbect:parseObject];
                    }
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index.integerValue inSection:0];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }else{
                    //insert
                    LifestyleCategory *category = [NSEntityDescription insertNewObjectForEntityForName:LifestyleCategoryName inManagedObjectContext:[SharedDataManager sharedInstance].managedObjectContext];
                    [category populateFromParseojbect:parseObject];
                    [self.dataSource addObject:category];
                    NSIndexPath *path = [NSIndexPath indexPathForRow:self.dataSource.count-1 inSection:0];
                    [self.tableView insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        }
    }];
}

-(void)loadRemoteDataForVisibleCells{
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        LifestyleCategory *category = self.dataSource[indexPath.row];
        NSString *imageName = [LifestyleCategoryName stringByAppendingString:category.name];
        
        if (cell.imageView.image != nil || [Helper isLocalImageExist:imageName isHighRes:NO]) {
            continue;
        }
        

        Query *query = [[Query alloc] init];
        __block UITableViewCell *weakCell = cell;
        [query getServerImageWithName:imageName isHighRes:NO completion:^(NSError *error, UIImage *image) {
            if (!error) {
                weakCell.imageView.image = image;
                
            }else{
                weakCell.imageView.image = nil;
            }
        }];
        [self.queries setObject:query forKey:indexPath];
    }
}

-(void)cancelRequestsForIndexpath:(NSIndexPath *)indexPath{
    Query *query = [self.queries objectForKey:indexPath];
    if (query) {
        [query cancelRequest];
    }
    [self.queries removeObjectForKey:indexPath];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 
    return self.dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *categoryCell = @"categoryCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:categoryCell forIndexPath:indexPath];
    
    LifestyleCategory *category = self.dataSource[indexPath.row];
    cell.textLabel.text = category.name;
    
    //reset in case its being reused
    cell.imageView.image = nil;
    //see if there is local cache
    NSString *imageName = [LifestyleCategoryName stringByAppendingString:category.name];
    
    UIImage *image = [Helper getLocalImageWithName:imageName isHighRes:NO];
    //update UI
    if (image) {
        cell.imageView.image = image;
    }else{
        if (!tableView.decelerating && !tableView.dragging) {
            
            __block UITableViewCell *weakCell = cell;
            Query *query = [[Query alloc] init];
            [self.queries setObject:query forKey:indexPath];
            [query getServerImageWithName:imageName isHighRes:NO completion:^(NSError *error, UIImage *image) {
                if (!error) {
                    weakCell.imageView.image = image;
                }else{
                    weakCell.imageView.image = nil;
                }
            }];
        }
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
