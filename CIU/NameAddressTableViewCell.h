//
//  NameAddressTableViewCell.h
//  DaDa
//
//  Created by Sihang Huang on 5/7/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NameAddressTableViewCell : UITableViewCell

+ (CGFloat)heightForCellWithName:(NSString *)name address:(NSString *)address cellWidth:(CGFloat)cellWidth;

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *addressLabel;

@end
