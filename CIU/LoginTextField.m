//
//  LoginTextField.m
//  CIU
//
//  Created by ZhangBoxuan on 14/11/10.
//  Copyright (c) 2014年 Huang, Sihang. All rights reserved.
//

#import "LoginTextField.h"

@implementation LoginTextField

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 10 , 0 );
}

//控制编辑文本时所在的位置，左右缩 10
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset( bounds , 10 , 0 );
}

- (void)drawPlaceholderInRect:(CGRect)rect {
    UIColor *color = [UIColor whiteColor];
    NSDictionary *attributes = @{NSForegroundColorAttributeName: color, NSFontAttributeName: self.font,};
    CGRect boundingRect = [self.placeholder boundingRectWithSize:rect.size options:0 attributes:attributes context:nil];
    [self.placeholder drawAtPoint:CGPointMake(0, (rect.size.height/2)-boundingRect.size.height/2) withAttributes:attributes];
}


@end
