//
//  NameTableViewCell.h
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EventTableViewCell;

@protocol EventTableViewCellDelegate

@optional

-(void)nameTextFieldEdited:(UITextField *)textField;
-(void)descriptionTextViewEdidited:(UITextView *)textView;
-(void)datePickerValueChanged:(UIDatePicker *)datePicker;
-(void)locationTextFieldChanged:(UITextField *)textField;
-(void)flagBadContentButtonTappedOnCell:(EventTableViewCell *)cell;

@end

@interface EventTableViewCell : UITableViewCell

// Typeface
+ (UIFont *)fontForEventName;
+ (UIFont *)fontForEventDate;
+ (UIFont *)fontForEventLocation;
+ (UIFont *)fontForEventDescription;
+ (CGFloat)eventLablesWidth;

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
@property (weak, nonatomic) IBOutlet UIButton *flagButton;

@end
