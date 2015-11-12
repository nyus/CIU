//
//  TermsAndPrivacyVC.m
//  CIU
//
//  Created by Sihang on 1/21/15.
//  Copyright (c) 2015 Huang, Jason. All rights reserved.
//

#import "TermsAndPrivacyVC.h"

@implementation TermsAndPrivacyVC

- (IBAction)cancelButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
