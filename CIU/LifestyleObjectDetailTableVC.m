//
//  LifestyleObjectDetailTableViewController.m
//  CIU
//
//  Created by Sihang on 8/24/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <Parse/Parse.h>
#import "LifestyleObjectDetailTableVC.h"
#import "LifestyleObject.h"
#import "GenericTableViewCell.h"
#import "LifestyleObject+Utilities.h"
#import "SharedDataManager.h"
#import "UIAlertView+Blocks.h"
#import "RestarauntAndMarketTableViewCell.h"

#define CONTENT_LABEL_WIDTH 280.0f

NSString *const kNamekey = @"Name";
NSString *const kPhoneKey = @"Phone";
NSString *const kWebsiteKey = @"Website";
NSString *const kAddressKey = @"Address";
NSString *const kHoursKey = @"Hours";
NSString *const kIntroductionKey = @"Introduction";

@interface LifestyleObjectDetailTableVC ()
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

@implementation LifestyleObjectDetailTableVC

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
    if ([self.lifestyleObject.category isEqualToString:@"Supermarket"]) {
        [[GAnalyticsManager shareManager] trackScreen:@"Supermarket Detail"];
    } else {
        [[GAnalyticsManager shareManager] trackScreen:@"Restaurant Detail"];
    }

    [self buildDataSource];
    [self syncWithServer];
}

-(void)syncWithServer{
    PFQuery *query = [[PFQuery alloc] initWithClassName:self.lifestyleObject.category];
    [query whereKey:@"objectId" equalTo:self.lifestyleObject.objectId];
    [query whereKey:@"updatedAt" greaterThan:self.lifestyleObject.updatedAt];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            [self.lifestyleObject populateFromParseObject:object];
            [[SharedDataManager sharedInstance] saveContext];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self buildDataSource];
                [self.tableView reloadData];
            });
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [Flurry logEvent:[NSString stringWithFormat:@"View %@ detail",self.lifestyleObject.category] timed:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:[NSString stringWithFormat:@"View %@ detail",self.lifestyleObject.category] withParameters:nil];
}

-(void)buildDataSource{
    
    self.dataSource = [NSMutableArray array];
    //name, phone, website, address, hours, introduction
    if (self.lifestyleObject.name) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.name,kNamekey, nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.phone) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.phone,kPhoneKey, nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.website) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.website,kWebsiteKey, nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.address) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.address,kAddressKey, nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.hours) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.hours,kHoursKey, nil];
        [self.dataSource addObject:dict];
    }
    if (self.lifestyleObject.introduction) {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:self.lifestyleObject.introduction,kIntroductionKey, nil];
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
    RestarauntAndMarketTableViewCell *cell;
    NSDictionary *dictionary = self.dataSource[indexPath.row];
    NSString *key = dictionary.allKeys[0];
    if ([key isEqualToString:@"Phone"] || [key isEqualToString:@"Address"]){
        cell = (RestarauntAndMarketTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"numberAddressCell" forIndexPath:indexPath];
        cell.phoneTextView.text = dictionary[key];
        cell.phoneTextView.textColor = [UIColor blueColor];
    }else{
        cell = (RestarauntAndMarketTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        if ([key isEqualToString:@"Name"] || [key isEqualToString:@"Website"] || [key isEqualToString:@"Introduction"]) {
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
    if ([key isEqualToString:@"Name"] || [key isEqualToString:@"Website"] || [key isEqualToString:@"Address"] || [key isEqualToString:@"Introduction"] || [key isEqualToString:@"Phone"]) {
        contentString = [dictionary objectForKey:key];
        
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
    
    CGRect rect = [contentString boundingRectWithSize:CGSizeMake(CONTENT_LABEL_WIDTH, MAXFLOAT)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName:[RestarauntAndMarketTableViewCell fontForContent]}
                                              context:NULL];
    
    return 20 + rect.size.height + ([key isEqualToString:@"Name"] ? 5 : 10);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dict = self.dataSource[indexPath.row];
    if (dict[kAddressKey]) {
        NSString *kOpenInMapsKey = @"Open in Maps";
        [UIAlertView showWithTitle:nil message:@"Display location in\nApple Maps?" cancelButtonTitle:@"Cancel" otherButtonTitles:@[kOpenInMapsKey] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:kOpenInMapsKey]) {
                NSString *addressString = @"http://maps.apple.com/?q=";
                addressString = [addressString stringByAppendingString:[dict[kAddressKey] stringByReplacingOccurrencesOfString:@" " withString:@"+"]];
                NSURL *url = [NSURL URLWithString:addressString];
                if([[UIApplication sharedApplication] canOpenURL:url]){
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }];
    } else if (dict[kPhoneKey]) {
        NSString *kCallKey = @"Call";
        [UIAlertView showWithTitle:nil message:[NSString stringWithFormat:@"Call %@?", dict[kPhoneKey]] cancelButtonTitle:@"Cancel" otherButtonTitles:@[kCallKey] tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:kCallKey]) {
                NSString *string = [NSString stringWithFormat:@"tel:%@", dict[kPhoneKey]];
                string = [string stringByReplacingOccurrencesOfString:@"(" withString:@""];
                string = [string stringByReplacingOccurrencesOfString:@")" withString:@""];
                string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
                string = [string stringByReplacingOccurrencesOfString:@"-" withString:@""];
                NSURL *url = [NSURL URLWithString:string];
                if([[UIApplication sharedApplication] canOpenURL:url]){
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
