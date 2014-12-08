//
//  UITextView+Utilities.m
//  FastPost
//
//  Created by Sihang Huang on 6/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "UITextView+Utilities.h"

@implementation UITextView (Utilities)
- (void)scrollTextViewToShowCursor {
    [self scrollRectToVisible:CGRectMake(0, 0, self.frame.size.width, self.contentSize.height) animated:YES];
}
@end
