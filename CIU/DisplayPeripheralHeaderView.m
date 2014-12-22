//
//  DisplayPeripheralHeaderView.m
//  CIU
//
//  Created by Sihang on 11/1/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "DisplayPeripheralHeaderView.h"
#import "UIColor+CIUColors.h"

@interface DisplayPeripheralHeaderView()
@property (copy) void (^completion)(double newValue);
@end

@implementation DisplayPeripheralHeaderView

- (instancetype)initWithStepValue:(NSNumber *)stepValue minimunStepValue:(NSNumber *)minStepValue maximunStepValue:(NSNumber *)maximunStepValue actionBlock:(void (^)(double))stepperValueChangedTo{
    self = [super init];
    
    if (self){
        
        self.completion = stepperValueChangedTo;
        self.backgroundColor = [UIColor themeGreen];
        self.contentLabel = [UILabel new];
        self.contentLabel.textColor = [UIColor themeTextGrey];
        self.contentLabel.numberOfLines = 0;
        self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSString *string;
        if (stepValue) {
            string = [NSString stringWithFormat:@"Results within %d miles",[stepValue intValue]];
        } else {
            string = @"Results within 5 miles";
        }
        
        self.contentLabel.text = string;
        [self addSubview:self.contentLabel];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-28.0-[_contentLabel(%f)]",200.0]
                                                                    options:kNilOptions
                                                                    metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_contentLabel)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_contentLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f constant:0.0f]];
        
        
        self.stepper = [[UIStepper alloc] initWithFrame:CGRectMake(0, 0, 94, 15)];
        self.stepper.translatesAutoresizingMaskIntoConstraints = NO;
        self.stepper.transform = CGAffineTransformMakeScale(0.75, 0.75);
        self.stepper.minimumValue = minStepValue.doubleValue;
        self.stepper.maximumValue = maximunStepValue.doubleValue;
        self.stepper.stepValue = 5.0;
        self.stepper.value = stepValue.doubleValue;
        self.stepper.tintColor = [UIColor themeTextGrey];
        [self.stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.stepper];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_stepper]-28.0-|"
                                                                     options:kNilOptions
                                                                     metrics:nil
                                                                       views:NSDictionaryOfVariableBindings(_stepper)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_stepper
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:self
                                                        attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f constant:0.0f]];
    }
    
    return self;
}

- (void)stepperValueChanged:(UIStepper *)stepper{
    if (self.completion) {
        double value = stepper.value;
        self.completion(value);
        NSString *string = [NSString stringWithFormat:@"Results within %d miles",(int)stepper.value];
//        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
//        NSRange range = [string rangeOfString:[NSString stringWithFormat:@"%d",(int)stepper.value]];
//        [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]} range:range];
//        self.contentLabel.attributedText = attributedString;
        self.contentLabel.text = string;
    }
}

@end
