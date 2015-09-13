//
//  SupermarketViewController.m
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <Masonry/Masonry.h>
#import "SupermarketVC.h"
#import "SupermarketMapVC.h"
#import "SupermarketTableVC.h"

@interface SupermarketVC ()

@property (nonatomic, strong) SupermarketTableVC *supermarketListVC;
@property (nonatomic, strong) SupermarketMapVC *supermarketMapVC;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation SupermarketVC

#pragma mark - View Setup

- (void)setUpSegmentedControl
{
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"List",@"Map"]];
    [self.segmentedControl addTarget:self
                              action:@selector(segmentedControlTapped:)
                    forControlEvents:UIControlEventValueChanged];
    self.segmentedControl.selectedSegmentIndex = 0;
    self.segmentedControl.accessibilityLabel = kListMapSegmentedControlAccessibilityLabel;
    
    self.navigationItem.titleView = self.segmentedControl;
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setUpSegmentedControl];
    
    _supermarketListVC = [[SupermarketTableVC alloc] init];
    [self addChildViewController:_supermarketListVC];
    [self addSupermarketListVCViewAndSetUpConstraints];
    [_supermarketListVC didMoveToParentViewController:self];
    
    _supermarketMapVC = [[SupermarketMapVC alloc] init];
    _supermarketMapVC.view.backgroundColor = [UIColor redColor];
    [self addChildViewController:_supermarketMapVC];
}

- (void)addSupermarketListVCViewAndSetUpConstraints
{
    [self.view addSubview:_supermarketListVC.view];
    [_supermarketListVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(0.0));
        make.bottom.equalTo(@(0.0));
        make.left.equalTo(@(0.0));
        make.right.equalTo(@(0.0));
    }];
}

- (void)addSupermarketMapVCAndSetUpConstraints
{
    [self.view addSubview:_supermarketMapVC.view];
    [_supermarketMapVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(0.0));
        make.bottom.equalTo(@(0.0));
        make.left.equalTo(@(0.0));
        make.right.equalTo(@(0.0));
    }];
}

#pragma mark - Action

-(void)segmentedControlTapped:(UISegmentedControl *)sender{
    
    //list view
    if (sender.selectedSegmentIndex == 0) {
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect"
                                                  label:@"Supermarker-list"
                                                  value:nil];
        [Flurry logEvent:@"Switch to list view"
          withParameters:@{@"screen":@"Supermarker"}];
        [self addChildViewController:_supermarketListVC];
        [self addSupermarketListVCViewAndSetUpConstraints];
        [_supermarketListVC willMoveToParentViewController:self];
        [self
         transitionFromViewController:_supermarketMapVC
         toViewController:_supermarketListVC
         duration:.3
         options:UIViewAnimationOptionCurveLinear
         animations:^{
         } completion:^(BOOL finished) {
             [_supermarketMapVC removeFromParentViewController];
             [_supermarketListVC didMoveToParentViewController:self];
         }];
    }else{
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect"
                                                  label:@"Supermarker-map"
                                                  value:nil];
        [Flurry logEvent:@"Switch to map view"
          withParameters:@{@"screen":@"Supermarker"}];
        [self addChildViewController:_supermarketMapVC];
        [self addSupermarketMapVCAndSetUpConstraints];
        [_supermarketMapVC willMoveToParentViewController:self];
        [self
         transitionFromViewController:_supermarketListVC
         toViewController:_supermarketMapVC
         duration:.3
         options:UIViewAnimationOptionCurveLinear
         animations:^{
             
         } completion:^(BOOL finished) {
             [_supermarketListVC removeFromParentViewController];
             [_supermarketMapVC didMoveToParentViewController:self];
         }];
    }
}
@end
