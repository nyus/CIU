//
//  HitTestView.m
//  CIU
//
//  Created by Sihang on 9/11/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "HitTestView.h"

@implementation HitTestView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *view = [super hitTest:point withEvent:event];
    if(view == self.targetView){
        return self.targetView;
    }else{
        return view;
    }
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
