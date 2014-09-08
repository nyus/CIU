//
//  CreateEventViewController.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "CreateEventViewController.h"
#import "EventTableViewCell.h"
#import <Parse/Parse.h>
#import "Reachability.h"
@interface CreateEventViewController()<UITableViewDelegate,UITableViewDataSource, EventTableViewCellDelegate>{
    NSString *eventName;
    NSString *eventContent;
    NSDate *eventDate;
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableviewBottomSpaceToBottomLayoutConstraint;
@end

@implementation CreateEventViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.tableviewBottomSpaceToBottomLayoutConstraint.constant += rect.size.height;
//    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
//    }];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Name";
    }else if (section==1){
        return @"Description";
    }else{
        return @"Date and Time";
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *nameCell = @"nameCell";
    static NSString *descriptionCell = @"descriptionCell";
    static NSString *timeCell = @"timeCell";
    
    EventTableViewCell *cell;
    if (indexPath.section == 0) {
        cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:nameCell forIndexPath:indexPath];
        [cell.nameTextField becomeFirstResponder];
    }else if (indexPath.section == 1){
        cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:descriptionCell forIndexPath:indexPath];
        cell.descriptionTextView.layer.cornerRadius = 3.0f;
        cell.descriptionTextView.layer.borderWidth = 0.5f;
        cell.descriptionTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    }else{
        cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:timeCell forIndexPath:indexPath];
        cell.datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:0];
        cell.datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:15552000];//half a year from now
    }
    
    cell.delegate = self;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section==0) {
        return 55.0f;
    }else if (indexPath.section == 1){
        return 175.0f;
    }else{
        return 190.0f;
    }
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)publishButtonTapped:(id)sender {
    
    if (![Reachability canReachInternet]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Looks like you do not have internet access. Please try again later." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if (!eventName){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please specify an event name!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if(!eventDate){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please specify an event date." delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
    }
    
    if(!eventContent) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Please tell us a bit more about the event." delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
    }
    
    PFObject *event = [[PFObject alloc] initWithClassName:@"Event"];
    [event setObject:eventName forKey:@"eventName"];
    [event setObject:eventContent forKey:@"eventContent"];
    [event setObject:eventDate forKey:@"eventDate"];
    [event setObject:[PFUser currentUser].username forKey:@"senderUsername"];
    [event setObject:[[PFUser currentUser] objectForKey:@"firstName"] forKey:@"senderFirstName"];
    [event setObject:[[PFUser currentUser] objectForKey:@"lastName"] forKey:@"senderLastName"];
    [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Event successfully published!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [alert show];
            [self performSelector:@selector(dismissSelf) withObject:nil afterDelay:.2];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Something went wrong, please try again." delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

-(void)dismissSelf{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - event table view cell delegate

-(void)nameTextFieldEdited:(UITextField *)textField{
    eventName = textField.text;
}

-(void)descriptionTextViewEdidited:(UITextView *)textView{
    eventContent = textView.text;
}

-(void)datePickerValueChanged:(UIDatePicker *)datePicker{
    eventDate = datePicker.date;
}
@end
