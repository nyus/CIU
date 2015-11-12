//
//  KIFUITestActor+Stepper.m
//  DaDa
//
//  Created by Sihang on 6/27/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "KIFUITestActor+Stepper.h"

@implementation KIFUITestActor (Stepper)

- (void)tapLeftButtonOnStepperWithAccessibilityLabel:(NSString *)label
{
    UIStepper *repsStepper = (UIStepper*)[tester waitForViewWithAccessibilityLabel:label];
    CGPoint stepperCenter = [repsStepper.window convertPoint:repsStepper.center
                                                    fromView:repsStepper.superview];
    
    CGPoint leftButtonLocationPoint = stepperCenter;
    leftButtonLocationPoint.x -= CGRectGetWidth(repsStepper.frame) / 4;
    
    [tester tapScreenAtPoint:leftButtonLocationPoint];

}

- (void)tapRightButtonOnStepperWithAccessibilityLabel:(NSString *)label
{
    UIStepper *repsStepper = (UIStepper*)[tester waitForViewWithAccessibilityLabel:label];
    CGPoint stepperCenter = [repsStepper.window convertPoint:repsStepper.center
                                                    fromView:repsStepper.superview];
    
    CGPoint rightButtonLocationPoint = stepperCenter;
    rightButtonLocationPoint.x += CGRectGetWidth(repsStepper.frame) / 4;
    
    [tester tapScreenAtPoint:rightButtonLocationPoint];
}


@end
