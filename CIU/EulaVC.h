//
//  EulaVC.h
//  DaDa
//
//  Created by Sihang on 4/3/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EulaVC;

@protocol EulaVCDelegate <NSObject>

- (void)acceptedEULAOnVC:(EulaVC *)vc;

@end

@interface EulaVC : UIViewController

@property (nonatomic, weak) id <EulaVCDelegate> delegate;

@end
