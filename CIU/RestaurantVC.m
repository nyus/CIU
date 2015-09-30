//
//  RestaurantViewController.m
//  DaDa
//
//  Created by Sihang on 9/12/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <Masonry/Masonry.h>
#import "RestaurantVC.h"
#import "RestaurantTableVC.h"
#import "RestaurantMapVC.h"

@interface RestaurantVC ()

@property (nonatomic, strong) RestaurantTableVC *restaurantListVC;
@property (nonatomic, strong) RestaurantMapVC *restaurantMapVC;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@end

@implementation RestaurantVC

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
    
    _restaurantListVC = [[RestaurantTableVC alloc] init];
    [self addChildViewController:_restaurantListVC];
    [self addRestaurantListVCViewAndSetUpConstraints];
    [_restaurantListVC didMoveToParentViewController:self];
    
    _restaurantMapVC = [[RestaurantMapVC alloc] init];
    _restaurantMapVC.view.backgroundColor = [UIColor redColor];
    [self addChildViewController:_restaurantMapVC];
    
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:self action:@selector(handleBackButton:)];
    self.navigationItem.leftBarButtonItem = back;
}

- (void)handleBackButton:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addRestaurantListVCViewAndSetUpConstraints
{
    [self.view addSubview:_restaurantListVC.view];
    [_restaurantListVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(0.0));
        make.bottom.equalTo(@(0.0));
        make.left.equalTo(@(0.0));
        make.right.equalTo(@(0.0));
    }];
}

- (void)addRestaurantMapVCAndSetUpConstraints
{
    [self.view addSubview:_restaurantMapVC.view];
    [_restaurantMapVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
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
                                                  label:@"Restaurant-list"
                                                  value:nil];
        [Flurry logEvent:@"Switch to list view"
          withParameters:@{@"screen":@"Restaurant"}];
        [self addChildViewController:_restaurantListVC];
        [self addRestaurantListVCViewAndSetUpConstraints];
        [_restaurantListVC willMoveToParentViewController:self];
        [self
         transitionFromViewController:_restaurantMapVC
         toViewController:_restaurantListVC
         duration:.3 
         options:UIViewAnimationOptionCurveLinear
         animations:^{
        } completion:^(BOOL finished) {
            [_restaurantMapVC removeFromParentViewController];
            [_restaurantListVC didMoveToParentViewController:self];
        }];
    }else{
        [[GAnalyticsManager shareManager] trackUIAction:@"segmentedControllSelect"
                                                  label:@"Restaurant-map"
                                                  value:nil];
        [Flurry logEvent:@"Switch to map view"
          withParameters:@{@"screen":@"Restaurant"}];
        [self addChildViewController:_restaurantMapVC];
        [self addRestaurantMapVCAndSetUpConstraints];
        [_restaurantMapVC willMoveToParentViewController:self];
        [self
         transitionFromViewController:_restaurantListVC
         toViewController:_restaurantMapVC
         duration:.3
         options:UIViewAnimationOptionCurveLinear
         animations:^{
             
         } completion:^(BOOL finished) {
             [_restaurantListVC removeFromParentViewController];
             [_restaurantMapVC didMoveToParentViewController:self];
         }];
    }
}

@end
