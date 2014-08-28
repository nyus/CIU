//
//  CommentTableViewCell.h
//  FastPost
//
//  Created by Sihang Huang on 6/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AvatarAndUsernameTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *commentStringLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@end
