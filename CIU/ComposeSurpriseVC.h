//
//  ComposeNewStatusViewController.h
//  FastPost
//
//  Created by Huang, Sihang on 12/4/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ComposeSurpriseVC : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *textPhotoSeparatorView;
@property (weak, nonatomic) IBOutlet UISwitch *anonymousSwitch;

- (IBAction)attachPhotoButtonTapped:(id)sender;
- (IBAction)sendButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;
- (IBAction)anonymousSwitchChanged:(id)sender;

@end
