//
//  NameTableViewCell.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
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

-(void)textViewDidChange:(UITextView *)textView{
    [self.delegate descriptionTextViewEdidited:textView];
}

@end
