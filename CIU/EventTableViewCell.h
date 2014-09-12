//
//  NameTableViewCell.h
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol EventTableViewCellDelegate
-(void)nameTextFieldEdited:(UITextField *)textField;
-(void)descriptionTextViewEdidited:(UITextView *)textView;
-(void)datePickerValueChanged:(UIDatePicker *)datePicker;
-(void)locationTextFieldChanged:(UITextField *)textField;
@end

@interface EventTableViewCell : UITableViewCell

//create event table view cell
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (assign, nonatomic) id<EventTableViewCellDelegate>delegate;
@property (weak, nonatomic) IBOutlet UITextField *locationTextField;

//event table view
@property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *eventDescriptionLabel;

@end
