//
//  GenericListMapVC.m
//  DaDa
//
//  Created by Sihang on 9/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <Masonry.h>
#import <MapKit/MapKit.h>
#import "GenericListMapVC.h"

@interface GenericListMapVC ()

@property (nonatomic, strong) UIButton *reResearchButton;

@end

@implementation GenericListMapVC

-(UIButton *)reResearchButton
{
    if (!_reResearchButton) {
        _reResearchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _reResearchButton.layer.cornerRadius = 10.0;
        _reResearchButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _reResearchButton.layer.borderWidth = 1.0;
        [_reResearchButton setTitle:@"Redo search in this area" forState:UIControlStateNormal];
        [_reResearchButton setTitleColor:[UIColor themeTextGrey] forState:UIControlStateNormal];
        _reResearchButton.titleLabel.font = [UIFont themeFontWithSize:18.0];
        _reResearchButton.hidden = YES;
        _reResearchButton.backgroundColor = [UIColor themeGreen];
        [_reResearchButton addTarget:self
                              action:@selector(reSearchButtonTapped:)
                    forControlEvents:UIControlEventTouchUpInside];
        [_mapView addSubview:_reResearchButton];
        
        [_reResearchButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(240.0));
            make.centerX.equalTo(_mapView);
            make.height.equalTo(@(44.0));
            make.bottom.equalTo(@(-10));
        }];
    }
    
    return _reResearchButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark - Action

- (void)reSearchButtonTapped:(UIButton *)reSearchButton
{
    [self handleRedoSearchButtonTapped];
}

- (void)handleRedoSearchButtonTapped
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Subclass needs to override -handleRedoSearchButtonTapped"
                                 userInfo:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

@end
