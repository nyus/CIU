#import "DDCopiableLabel.h"

@implementation DDCopiableLabel

#pragma mark Initialization

- (void)attachTapHandler
{
    [self setUserInteractionEnabled:YES];
    UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(handleTap:)];
    UILongPressGestureRecognizer *longPree = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    [self addGestureRecognizer
    [self addGestureRecognizer:longPree];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self attachTapHandler];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self attachTapHandler];
}

#pragma mark Clipboard

- (void)copy:(id)sender
{
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    pboard.string = self.text;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)handleTap:(UIGestureRecognizer*)recognizer
{
    [self becomeFirstResponder];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    CGRect rect = [self.text boundingRectWithSize:CGSizeMake(MAXFLOAT, CGRectGetHeight(self.frame))
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName : self.font}
                                          context:nil];
    rect.origin = self.frame.origin;
    [menu setTargetRect:rect inView:self.superview];
    [menu setMenuVisible:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
