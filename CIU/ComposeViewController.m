//
//  ComposeViewController.m
//  CIU
//
//  Created by Huang, Sihang on 9/15/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "ComposeViewController.h"
#import <Parse/Parse.h>
#import "Helper.h"

@interface ComposeViewController ()

@end

@implementation ComposeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [Flurry logEvent:[NSString stringWithFormat:@"View compose %@",[LifestyleCategory nameForCategoryType:self.categoryType]] timed:YES];
    [self.textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:[NSString stringWithFormat:@"View compose %@",[LifestyleCategory nameForCategoryType:self.categoryType]] withParameters:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)publishButtonTapped:(id)sender {
    
    if (self.textView.text == nil || [self.textView.text isEqualToString:@""]) {
        return;
    }
    
    NSString *parseClassName = [LifestyleCategory getParseClassNameForCategoryType:self.categoryType];
    if (parseClassName==nil) {
        return;
    }
    
    __block ComposeViewController *weakSelf = self;
    PFObject *object = [[PFObject alloc] initWithClassName:parseClassName];
    [object setObject:self.textView.text forKey:@"content"];
    [object setObject:[PFUser currentUser].username forKey:@"posterUsername"];
    [object setObject:parseClassName forKey:@"category"];
    [object setObject:@NO forKey:@"isBadContent"];
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
