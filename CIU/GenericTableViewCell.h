//
//  GenericTableViewCell.h
//  CIU
//
//  Created by Sihang on 8/24/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GenericTableViewCell : UITableViewCell
//object detail table view cell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@end
