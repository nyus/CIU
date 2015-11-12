//
//  DisplayPeripheralHeaderView.h
//  CIU
//
//  Created by Sihang on 11/1/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ContentMode)
{
    ContentModeLeft,
    ContentModeCenter
};

@interface DisplayPeripheralHeaderView : UIView

@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIStepper *stepper;

- (instancetype)initWithCurrentValue:(NSNumber *)currentValue
                           stepValue:(NSNumber *)stepValue
                        minimunValue:(NSNumber *)minimunValue
                        maximunValue:(NSNumber *)maximunValue
                         contentMode:(ContentMode)contentMode
                         actionBlock:(void(^)(double newValue))stepperValueChangedTo;

@end
