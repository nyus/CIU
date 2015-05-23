//
//  ComposeViewController.m
//  CIU
//
//  Created by Huang, Sihang on 9/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "ComposeVC.h"
#import <Parse/Parse.h>
#import "Helper.h"
#import "NSString+Utilities.h"

@implementation ComposeVC

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [Flurry logEvent:[NSString stringWithFormat:@"View compose %@",[LifestyleCategory nameForCategoryType:self.categoryType]] timed:YES];
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [Flurry endTimedEvent:[NSString stringWithFormat:@"View compose %@",[LifestyleCategory nameForCategoryType:self.categoryType]] withParameters:nil];
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)publishButtonTapped:(id)sender {
    
    if (self.textView.text == nil || [self.textView.text isEqualToString:@""]) {
        return;
    }
    
    BOOL isAdmin = [[PFUser currentUser][DDIsAdminKey] boolValue];
    if (!isAdmin && [self.textView.text containsURL]) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"External links are not allowed.", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Got it", nil)
                          otherButtonTitles:nil, nil] show];
        
        return;
    }
    
    NSString *parseClassName = [LifestyleCategory getParseClassNameForCategoryType:self.categoryType];
    
    if (parseClassName==nil) {
        return;
    }
    
    __block ComposeVC *weakSelf = self;
    PFObject *object = [[PFObject alloc] initWithClassName:parseClassName];
    [object setObject:self.textView.text forKey:@"content"];
    [object setObject:[PFUser currentUser].username forKey:DDPosterUserNameKey];
    [object setObject:parseClassName forKey:@"category"];
    [object setObject:@NO forKey:DDIsBadContentKey];
    
    NSDictionary *userLocation = [Helper userLocation];
    if (self.categoryType == DDCategoryTypeTradeAndSell && userLocation) {
        object[DDLatitudeKey] = userLocation[DDLatitudeKey];
        object[DDLongitudeKey] = userLocation[DDLongitudeKey];
    }
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            });
            
            [[GAnalyticsManager shareManager] trackUIAction:[NSString stringWithFormat:@"publish %@",parseClassName] label:nil value:nil];
            [Flurry logEvent:[NSString stringWithFormat:@"publish %@",parseClassName]];
            
        }else{
            if (![Reachability canReachInternet]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"There is no internet connection. Please try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                });
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Something went wrong. Please try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
                    [alert show];
                });
            }
        }
    }];
}

@end
