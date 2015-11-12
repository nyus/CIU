//
//  KIFUITestActor+Stepper.h
//  DaDa
//
//  Created by Sihang on 6/27/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "KIFUITestActor.h"

@interface KIFUITestActor (Stepper)

- (void)tapLeftButtonOnStepperWithAccessibilityLabel:(NSString *)label;

- (void)tapRightButtonOnStepperWithAccessibilityLabel:(NSString *)label;

@end
