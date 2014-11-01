//
//  DisplayPeripheralHeaderView.h
//  CIU
//
//  Created by Sihang on 11/1/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DisplayPeripheralHeaderView : UIView

@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIStepper *stepper;

- (instancetype)initWithBlock:(void(^)(double newValue))stepperValueChangedTo;

@end
