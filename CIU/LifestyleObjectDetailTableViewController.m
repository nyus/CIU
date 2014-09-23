//
//  LifestyleObjectDetailTableViewController.m
//  CIU
//
//  Created by Sihang on 8/24/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "LifestyleObjectDetailTableViewController.h"
#import "LifestyleObject.h"
#import "GenericTableViewCell.h"
#import "LifestyleObject+Utilities.h"
#import "SharedDataManager.h"
#import <Parse/Parse.h>
#define CONTENT_LABEL_WIDTH 280.0f
@interface LifestyleObjectDetailTableViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation LifestyleObjectDetailTableViewController

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
    [self buildDataSource];
    [self syncWithServer];
}

-(void)syncWithServer{
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"LifestyleObject"];
    [query whereKey:@"objectId" equalTo:self.lifestyleObject.objectId];
    [query whereKey:@"updatedAt" greaterThan:self.lifestyleObject.updatedAt];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            [self.lifestyleObject populateFromObject:object];
            [[SharedDataManager sharedInstance] saveContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self buildDataSource];
                [self.tableView reloadData];
            });
        }
    }];
}

-(void)buildDataSource{
    
    self.dataSource = [NSMutableArray array];
    //name, phone, website, address, hours, introduction
    if (self.lifestyleObject.name) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.name,@"Name", nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.phone) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.phone,@"Phone", nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.website) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.website,@"Website", nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.address) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.address,@"Address", nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.hours) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.hours,@"Hours", nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.introduction) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.introduction,@"Introduction", nil];
        [self.dataSource addObject:dict];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GenericTableViewCell *cell;
    NSDictionary *dictionary = self.dataSource[indexPath.row];
    NSString *key = dictionary.allKeys[0];
    if ([key isEqualToString:@"Phone"]){
        cell = (GenericTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"numberCell" forIndexPath:indexPath];
        cell.phoneTextView.text = dictionary[key];
    }else{
        cell = (GenericTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        if ([key isEqualToString:@"Name"] || [key isEqualToString:@"Website"] || [key isEqualToString:@"Address"] || [key isEqualToString:@"Introduction"]) {
            cell.contentLabel.text = [dictionary objectForKey:key];
        }else if([key isEqualToString:@"Hours"]){
            NSMutableString *string = [NSMutableString string];
            NSArray *array = (NSArray *)[dictionary objectForKey:key];
            for (int i =0; i<array.count; i++) {
                if (i!=array.count-1) {
                    [string appendFormat:@"%@\n",array[i]];
                }else{
                    [string appendFormat:@"%@",array[i]];
                }
            }
            cell.contentLabel.text = string;
        }
    }
    
    cell.titleLabel.text = key;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *contentString = nil;
    NSDictionary *dictionary = self.dataSource[indexPath.row];
    NSString *key = dictionary.allKeys[0];
    if ([key isEqualToString:@"Name"] || [key isEqualToString:@"Website"] || [key isEqualToString:@"Address"] || [key isEqualToString:@"Introduction"]) {
        contentString = [dictionary objectForKey:key];
    }else if ([key isEqualToString:@"Phone"]){
        //could have several phone numbers
        NSArray *array = (NSArray *)[dictionary objectForKey:key];
        NSMutableString *string = [NSMutableString string];
        for (int i =0; i<array.count; i++) {
            if (i!=array.count-1) {
                [string appendFormat:@"%@\n",array[i]];
            }else{
                [string appendFormat:@"%@",array[i]];
            }
        }
        contentString = string;
    }else if([key isEqualToString:@"Hours"]){
        NSMutableString *string = [NSMutableString string];
        NSArray *array = (NSArray *)[dictionary objectForKey:key];
        for (int i =0; i<array.count; i++) {
            if (i!=array.count-1) {
                [string appendFormat:@"%@\n",array[i]];
            }else{
                [string appendFormat:@"%@",array[i]];
            }
        }
        contentString = string;
    }
    
    CGRect rect = [contentString boundingRectWithSize:CGSizeMake(CONTENT_LABEL_WIDTH, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:NULL];
    
    return 20+rect.size.height+5;
}

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
