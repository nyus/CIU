//
//  EulaVC.m
//  DaDa
//
//  Created by Sihang on 4/3/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "EulaVC.h"

@interface EulaVC ()

@end

@implementation EulaVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)acceptButtonTapped:(id)sender {
    [self.delegate acceptedEULAOnVC:self];
}

- (IBAction)declineButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
