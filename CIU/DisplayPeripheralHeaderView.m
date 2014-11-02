//
//  DisplayPeripheralHeaderView.m
//  CIU
//
//  Created by Sihang on 11/1/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "DisplayPeripheralHeaderView.h"

@interface DisplayPeripheralHeaderView()
@property (copy) void (^completion)(double newValue);
@end

@implementation DisplayPeripheralHeaderView

- (instancetype)initWithBlock:(void (^)(double))stepperValueChangedTo{
    self = [super init];
    
    if (self){
        
        self.completion = stepperValueChangedTo;
        self.backgroundColor = [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
        self.contentLabel = [UILabel new];
        self.contentLabel.numberOfLines = 0;
        self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSString *string = @"Results within 5 miles.";
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
        NSRange range = [string rangeOfString:@"5"];
        [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]} range:range];
        self.contentLabel.attributedText = attributedString;
        [self addSubview:self.contentLabel];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-15.0-[_contentLabel(%f)]",200.0]
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
        self.stepper.minimumValue = 5.0;
        self.stepper.maximumValue = 30.0;
        self.stepper.stepValue = 5.0;
        [self.stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.stepper];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_stepper]-15.0-|"
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
        NSString *string = [NSString stringWithFormat:@"Results within %d miles.",(int)stepper.value];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
        NSRange range = [string rangeOfString:[NSString stringWithFormat:@"%d",(int)stepper.value]];
        [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor blueColor]} range:range];
        self.contentLabel.attributedText = attributedString;
    }
}

@end
