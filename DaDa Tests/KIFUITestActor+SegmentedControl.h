//
//  KIFUITestActor+SegmentedControl.h
//  DaDa
//
//  Created by Sihang on 6/27/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "KIFUITestActor.h"

@interface KIFUITestActor (SegmentedControl)

- (void)tapItemAtIndex:(NSInteger)index totalItemCount:(NSInteger)itemCount forSegmentedControlWithAccessibilityLabel:(NSString *)label;

@end
