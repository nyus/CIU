//
//  DisplayPeripheralHeaderView.h
//  CIU
//
//  Created by Sihang on 11/1/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *kDataDisplayRadiusKey;

@interface DisplayPeripheralHeaderView : UIView

@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIStepper *stepper;

- (instancetype)initWithBlock:(void(^)(double newValue))stepperValueChangedTo;

@end
