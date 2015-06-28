//
//  KIFUITestActor+SegmentedControl.m
//  DaDa
//
//  Created by Sihang on 6/27/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "KIFUITestActor+SegmentedControl.h"

@implementation KIFUITestActor (SegmentedControl)

- (void)tapItemAtIndex:(NSInteger)index totalItemCount:(NSInteger)itemCount forSegmentedControlWithAccessibilityLabel:(NSString *)label
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)[tester waitForViewWithAccessibilityLabel:label];
    
    CGPoint origin = [segmentedControl.window convertPoint:segmentedControl.frame.origin
                                                  fromView:segmentedControl.superview];
    
    CGFloat itemWidth = CGRectGetWidth(segmentedControl.frame) / itemCount;
    
    CGPoint centerOfItemAtIndex = CGPointMake(origin.x + itemWidth * index + itemWidth / 2, origin.y + CGRectGetHeight(segmentedControl.frame) / 2);
    
    [tester tapScreenAtPoint:centerOfItemAtIndex];
}

@end
