//
//  StartupViewController.m
//  CIU
//
//  Created by Huang, Jason on 8/14/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "StartupViewController.h"
NS_ENUM(NSUInteger, SideBarStatus){
    SideBarStatusClosed=0,
    SideBarStatusOpen=1
};
#define SIDE_BAR_OPEN_DISTANCE 150.0f
#define SIDE_BAR_CLOSE_DISTANCE 0.0f
#define AVATAR_CELL_HEIGHT 102.0f
#define OTHER_CELL_HEIGHT 44.0f
@interface StartupViewController()<UITableViewDataSource,UITableViewDelegate>{
    CGPoint previousPoint;
}
@end

@implementation StartupViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSideBarSlideOpen) name:@"sideBarSlideOpen" object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)handlePanContainerView:(UIPanGestureRecognizer *)sender {
   CGPoint point = [sender translationInView:self.view];
    float deltaX = point.x - previousPoint.x;
    previousPoint = point;
    if (self.containerViewLeadingSpaceConstraint.constant + deltaX <0 || self.containerViewLeadingSpaceConstraint.constant + deltaX >SIDE_BAR_OPEN_DISTANCE) {
        return;
    }
    self.containerViewLeadingSpaceConstraint.constant += deltaX;
    
    //reset
    if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateFailed) {
        previousPoint = CGPointZero;
        [self animateSideBarToOpenOrClose];
    }
}

-(void)animateSideBarToOpenOrClose{
    
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if (self.containerViewLeadingSpaceConstraint.constant < SIDE_BAR_OPEN_DISTANCE/2) {
        
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_CLOSE_DISTANCE;
    }else{
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_OPEN_DISTANCE;
    }
    
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

-(void)handleSideBarSlideOpen{
    [self animateSideBarWhenMenuTapped];
}

-(void)animateSideBarWhenMenuTapped{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    
    if (self.containerViewLeadingSpaceConstraint.constant==0) {
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_OPEN_DISTANCE;
    }else{
        self.containerViewLeadingSpaceConstraint.constant = SIDE_BAR_CLOSE_DISTANCE;
    }
    
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }];
}

#pragma mark - UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"avatarCell" forIndexPath:indexPath];
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return AVATAR_CELL_HEIGHT;
    }else{
        return OTHER_CELL_HEIGHT;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return AVATAR_CELL_HEIGHT;
    }else{
        return OTHER_CELL_HEIGHT;
    }
}
@end
