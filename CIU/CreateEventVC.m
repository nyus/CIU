//
//  CreateEventViewController.m
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CreateEventVC.h"
#import "EventTableViewCell.h"
#import <Parse/Parse.h>
#import "HitTestView.h"
#import "Helper.h"
#import "NSString+Utilities.h"

const float kHorizontalMarginLeft = 20.0;
const float kOptionsTBViewHeight = 280.0;

@interface CreateEventVC()<UITableViewDelegate,UITableViewDataSource, EventTableViewCellDelegate,UIGestureRecognizerDelegate>{
    NSString *_eventName;
    NSString *_eventContent;
    NSDate *_eventDate;
    NSString *_eventLocation;
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableviewBottomSpaceToBottomLayoutConstraint;
@property (strong, nonatomic) NSArray *dataSource;
@property (strong, nonatomic) NSMutableArray *optionsTBViewDatasource;
@property (strong, nonatomic) UITableView *optionsTBView;
@property (strong, nonatomic) HitTestView *optionsTBViewShadow;
@property (strong, nonatomic) NSArray *placeMarksArray;
@property (strong, nonatomic) NSIndexPath *selectedPlaceMarkIndexPath;
@property (nonatomic) BOOL locationValidated;
@property (nonatomic, strong) __block CLLocation *adminEventLocation;

@end

@implementation CreateEventVC

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
    [[GAnalyticsManager shareManager] trackScreen:@"Create Event"];
    self.dataSource = [NSArray arrayWithObjects:@"Event Name",@"Event Location",@"Event Description",@"Event Date and Time", nil];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [Flurry logEvent:@"View create event" timed:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [Flurry endTimedEvent:@"View create event" withParameters:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    self.tableviewBottomSpaceToBottomLayoutConstraint.constant = rect.size.height;
    [self.view layoutIfNeeded];
}

-(void)handleKeyboardWillHide:(NSNotification *)notification{
    self.tableviewBottomSpaceToBottomLayoutConstraint.constant =0;
    [self.view layoutIfNeeded];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView==self.optionsTBView) {
        return 1;
    }else{
        return self.dataSource.count;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView==self.optionsTBView) {
        return self.optionsTBViewDatasource.count;
    }else{
        return 1;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView==self.optionsTBView) {
        
        return @"Did you mean?";
    }else{
        
        return self.dataSource[section];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (tableView==self.optionsTBView) {
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.translatesAutoresizingMaskIntoConstraints = NO;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.textLabel.numberOfLines = 5;//this will make the cell textlabel to accomondate text
        cell.textLabel.text = self.optionsTBViewDatasource[indexPath.row];
        return cell;
    }else{
        EventTableViewCell *cell = (EventTableViewCell *)[tableView dequeueReusableCellWithIdentifier:self.dataSource[indexPath.section] forIndexPath:indexPath];
        if (indexPath.section == 0) {
            //this is because when we show options tb view, we first dismiss keyboard, then call layout if needed, and tableview gets reloaded, so keyboard will come up again.
            if(self.optionsTBViewShadow.alpha==0.0f){
                [cell.nameTextField becomeFirstResponder];
            }
        }else if (indexPath.section == 1){
            
            
        }else if (indexPath.section == 2){
            cell.descriptionTextView.layer.cornerRadius = 3.0f;
            cell.descriptionTextView.layer.borderWidth = 0.5f;
            cell.descriptionTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;
        }else{
            
            cell.datePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:-15552000];//0];
            cell.datePicker.maximumDate = [NSDate dateWithTimeIntervalSinceNow:15552000];//half a year from now
        }
        
        cell.delegate = self;
        
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView==self.optionsTBView) {
        NSString *string = self.optionsTBViewDatasource[indexPath.row];
        CGRect rect = [string boundingRectWithSize:CGSizeMake(tableView.frame.size.width-40, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]} context:NULL];
        return rect.size.height + 20;
    }else{
        if (indexPath.section==0 || indexPath.section == 1) {
            return 55.0f;
        }else if (indexPath.section == 2){
            return 175.0f;
        }else{
            return 190.0f;
        }
    }
}

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createVerifyLocationTBView
{
    self.optionsTBViewShadow = [[HitTestView alloc] initWithFrame:self.view.frame];
    self.optionsTBViewShadow.backgroundColor = [UIColor darkGrayColor];
    self.optionsTBViewShadow.alpha = 0.7f;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnOptionsTableViewShadow)];
    tap.delegate = self;
    [self.optionsTBViewShadow addGestureRecognizer:tap];
    self.optionsTBView = [[UITableView alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       kOptionsTBViewHeight,
                                                                       CGRectGetWidth(self.view.frame) - 2 * kHorizontalMarginLeft)
                                                      style:UITableViewStylePlain];
    self.optionsTBView.center = self.optionsTBViewShadow.center;
    self.optionsTBView.delegate = self;
    self.optionsTBView.dataSource = self;
    
    [self.optionsTBViewShadow addSubview:self.optionsTBView];
    [self.view addSubview:self.optionsTBViewShadow];
}

- (IBAction)publishButtonTapped:(id)sender {
    
    if (![Reachability canReachInternet]) {
        [TSMessage showNotificationInViewController:self
                                              title:NSLocalizedString(@"There is no internet connection. Please try again" , nil)
                                           subtitle:nil
                                               type:TSMessageNotificationTypeError
                                 accessibilityLabel:nil];
        return;
    }
    
    if (!_eventName){
        [TSMessage showNotificationInViewController:self
                                              title:NSLocalizedString(@"Please Specify Event Name", nil)
                                           subtitle:nil
                                               type:TSMessageNotificationTypeError
                                 accessibilityLabel:kSpecifyEventNameAccessibilityLabel];
        
        return;
    }
    
    if(!_eventDate){
        [TSMessage showNotificationInViewController:self
                                              title:NSLocalizedString(@"Please Specify Event Date", nil)
                                           subtitle:nil
                                               type:TSMessageNotificationTypeError
                                 accessibilityLabel:kSpecifyEventDateAccessibilityLabel];
        
        return;
    }
    
    BOOL isAdmin = [[PFUser currentUser][DDIsAdminKey] boolValue];
    
    if(!_eventContent || (!isAdmin && ([_eventContent containsURL] || [_eventName containsURL]))) {
        
        if (!_eventContent) {
            [TSMessage showNotificationInViewController:self
                                                  title:NSLocalizedString(@"Please Describe The Event", nil)
                                               subtitle:nil
                                                   type:TSMessageNotificationTypeWarning
                                     accessibilityLabel:kTellMoreAboutEventAccessibilityLabel];
        } else {
            [TSMessage showNotificationInViewController:self
                                                  title:NSLocalizedString(@"Enternal Links Are Not Allowed", nil)
                                               subtitle:nil
                                                   type:TSMessageNotificationTypeWarning
                                     accessibilityLabel:kExternalLinksNotAllowedAccessibilityLabel];
        }
        
        return;
    }
    
    if (!_eventLocation) {
        [TSMessage showNotificationInViewController:self
                                              title:NSLocalizedString(@"Please Specify Event Location", nil)
                                           subtitle:nil
                                               type:TSMessageNotificationTypeError
                                 accessibilityLabel:kSpecifyEventLocationAccessibilityLabel];
        
        return;
    } else{
        
        if (!self.locationValidated) {
            //verify location
            CLGeocoder *geocoder = [[CLGeocoder alloc] init];
            [geocoder geocodeAddressString:_eventLocation completionHandler:^(NSArray *placemarks, NSError *error) {
                
                if (error) {
                    NSLog(@"geocoder failed to geocode address:%@", _eventLocation);
                } else {
                    
                    if (placemarks.count == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [TSMessage showNotificationInViewController:self
                                                                  title:NSLocalizedString(@"Looks like the event location is invalid. Please check again.", nil)
                                                               subtitle:nil
                                                                   type:TSMessageNotificationTypeWarning
                                                     accessibilityLabel:kSpecifyEventLocationAccessibilityLabel];
                        });
                    } else {
                        
                        if (!self.optionsTBView) {
                            [self createVerifyLocationTBView];
                        }
                        
                        self.optionsTBViewDatasource = nil;
                        self.placeMarksArray = placemarks;
                        self.optionsTBViewDatasource = [NSMutableArray array];
                        for (CLPlacemark *placeMark in placemarks) {
                            NSDictionary *dict = placeMark.addressDictionary;
                            NSMutableString *text = [[NSMutableString alloc] init];
                            if (dict[@"Street"]) {
                                [text appendFormat:@"%@, ",dict[@"Street"]];
                            }
                            if(dict[@"City"]){
                                [text appendFormat:@"%@, ",dict[@"City"]];
                            }
                            if (dict[@"State"]) {
                                [text appendFormat:@"%@",dict[@"State"]];
                            }
                            
                            [self.optionsTBViewDatasource addObject:text];
                            
                            self.adminEventLocation = placeMark.location;
                        }
                        [self.optionsTBView reloadData];
                        
                        //dismiss keyboard
                        [self.view endEditing:YES];
                        //bring up table view
                        [UIView animateWithDuration:.3 animations:^{
                            self.optionsTBViewShadow.alpha = 1.0f;
                        }];
                        
                    }
                }
            }];
        } else {
            
            //publish
            PFObject *event = [[PFObject alloc] initWithClassName:DDEventParseClassName];
            [event setObject:_eventName forKey:DDEventNameKey];
            [event setObject:_eventContent forKey:DDEventContentKey];
            [event setObject:_eventDate forKey:DDEventDateKey];
            [event setObject:@NO forKey:DDIsBadContentKey];
            if (isAdmin) {
                [event setObject:@(self.adminEventLocation.coordinate.latitude) forKey:DDLatitudeKey];
                [event setObject:@(self.adminEventLocation.coordinate.longitude) forKey:DDLongitudeKey];
            } else {
                NSDictionary *dictionary = [Helper userLocation];
                [event setObject:dictionary[DDLatitudeKey] forKey:DDLatitudeKey];
                [event setObject:dictionary[DDLongitudeKey] forKey:DDLongitudeKey];
            }
            [event setObject:_eventLocation forKey:DDEventLocationKey];
            [event setObject:[PFUser currentUser].username forKey:DDSenderUserNameKey];
            [event setObject:[[PFUser currentUser] objectForKey:DDFirstNameKey] forKey:DDSenderFirstNameKey];
            [event setObject:[[PFUser currentUser] objectForKey:DDLastNameKey] forKey:DDSenderLastNameKey];
            event[DDIsStickyPostKey] = [[PFUser currentUser] objectForKey:DDIsAdminKey];
            
            [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    [TSMessage showNotificationInViewController:self.parentViewController
                                                          title:NSLocalizedString(@"Event Successfully Published", nil)
                                                       subtitle:nil
                                                           type:TSMessageNotificationTypeSuccess
                                             accessibilityLabel:kSuccessfulPublishEventAccessibilityLabel];
                    [self performSelector:@selector(dismissSelf) withObject:nil afterDelay:0.8];
                }else{
                    [TSMessage showNotificationInViewController:self
                                                          title:NSLocalizedString(@"Oops Something Went Wrong\nPlease Try Again Later", nil)
                                                       subtitle:nil
                                                           type:TSMessageNotificationTypeError
                                             accessibilityLabel:kSomethingWentWrongAccessibilityLabel];
                }
                
                NSNumber *latitude = isAdmin ? @(self.adminEventLocation.coordinate.latitude) : [Helper userLocation][DDLatitudeKey];
                NSNumber *longitude = isAdmin ? @(self.adminEventLocation.coordinate.longitude) : [Helper userLocation][DDLongitudeKey];
                [AnalyticsManager logPublicEventWithLatitude:latitude longitude:longitude];
            }];
        }
    }
}

- (void)dismissSelf
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView==self.optionsTBView) {
        self.locationValidated = YES;
        self.selectedPlaceMarkIndexPath = indexPath;
        EventTableViewCell *locationCell = (EventTableViewCell *)[self.tableview cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        locationCell.locationTextField.text = self.optionsTBViewDatasource[indexPath.row];
        _eventLocation = self.optionsTBViewDatasource[indexPath.row];
        [self hideOptionsTBViewShadow];
    }
}

-(void)hideOptionsTBViewShadow{
    [UIView animateWithDuration:.3 animations:^{
        self.optionsTBViewShadow.alpha = 0.0f;
    }];
}

-(void)handleTapOnOptionsTableViewShadow{
    [self hideOptionsTBViewShadow];
}

-(void)dismissSelf:(id)object{
    if ([object isKindOfClass:[UIAlertView class]]) {
        UIAlertView *alert = (UIAlertView *)object;
        [alert dismissWithClickedButtonIndex:0 animated:YES];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    UIView *touchedView = touch.view;
    //dont let tap intercept tapping on options table view
    if(![touchedView isKindOfClass:[HitTestView class]]){
        return NO;
    }
    return YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    return YES;
}
#pragma mark - event table view cell delegate

-(void)nameTextFieldEdited:(UITextField *)textField{
    _eventName = textField.text;
}

-(void)descriptionTextViewEdidited:(UITextView *)textView{
    _eventContent = textView.text;
}

-(void)datePickerValueChanged:(UIDatePicker *)datePicker{
    _eventDate = datePicker.date;
}

-(void)locationTextFieldChanged:(UITextField *)textField{
    self.locationValidated = NO;
    _eventLocation = textField.text;
}
@end
