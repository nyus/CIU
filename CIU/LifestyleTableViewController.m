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
static NSString *LifestyleCategoryName = @"LifestyleCategory";
@interface LifestyleTableViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)pullDataFromLocal{
    
    if (!self.dataSource) {
        self.dataSource = [NSMutableArray array];
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:LifestyleCategoryName];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"SELF.importance"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[SharedDataManager sharedInstance].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects != nil) {
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
                    self.tableView reloadRowsAtIndexPaths:<#(NSArray *)#> withRowAnimation:<#(UITableViewRowAnimation)#>
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
