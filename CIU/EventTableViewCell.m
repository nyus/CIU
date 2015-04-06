//
//  NameTableViewCell.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "EventTableViewCell.h"
@interface EventTableViewCell()<UITextViewDelegate>
@end
@implementation EventTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    self.descriptionTextView.delegate = self;
}

- (IBAction)datePickerValueChanged:(id)sender {
    [self.delegate datePickerValueChanged:sender];
}
- (IBAction)nameTextFieldChanged:(id)sender {
    [self.delegate nameTextFieldEdited:sender];
}
- (IBAction)locationTextFieldChanged:(id)sender {
    [self.delegate locationTextFieldChanged:sender];
}

-(void)textViewDidChange:(UITextView *)textView{
    [self.delegate descriptionTextViewEdidited:textView];
}

- (IBAction)flagBadContentButtonTapped:(id)sender {
    [self.delegate flagBadContentButtonTappedOnCell:self];
}

+ (CGFloat)eventLablesWidth
{
    return 273.0;
}

// Typeface
+ (UIFont *)fontForEventName
{
    return [UIFont fontWithName:@"Helvetica-Bold" size:18.0];
}

+ (UIFont *)fontForEventDate
{
    return [UIFont fontWithName:@"Helvetica-Light" size:14.0];
}
+ (UIFont *)fontForEventLocation
{
    return [UIFont fontWithName:@"Helvetica-Light" size:14.0];
}

+ (UIFont *)fontForEventDescription
{
    return [UIFont fontWithName:@"Helvetica-Light" size:14.0];
}

@end
