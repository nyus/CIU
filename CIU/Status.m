//
//  DisplayObject.m
//  FastPost
//
//  Created by Huang, Sihang on 11/26/13.
//  Copyright (c) 2013 Huang, Sihang. All rights reserved.
//

#import "Status.h"
#import <Parse/Parse.h>
@interface Status(){
    NSTimer *_timer;
}
@end

@implementation Status

-(id)initWithPFObject:(PFObject *)pfObject{
    self = [super init];
    if (self) {
        self.objectid = pfObject.objectId;
        self.message = [pfObject objectForKey:@"message"];
        self.createdAt = pfObject.createdAt;
        self.updatedAt = pfObject.updatedAt;
        self.picture = pfObject[@"picture"];
        self.posterUsername = pfObject[@"posterUsername"];
        self.expirationDate = pfObject[@"expirationDate"];
        self.revivable = pfObject[@"revivable"];
        self.expirationTimeInSec = pfObject[@"expirationTimeInSec"];
        self.likeCount = pfObject[@"likeCount"];
        self.reviveCount = pfObject[@"reviveCount"];
        self.commentCount = pfObject[@"commentCount"];
        self.photoCount = pfObject[@"photoCount"];
        self.pfObject = pfObject;
        //StatusTableCell.countDownLabel.text needs to be based on self.countDownMessage and converted to xx:xx
//        self.countDownMessage = [NSString stringWithFormat:@"%d",(int)[pfObject[@"expirationDate"] timeIntervalSinceDate:[NSDate date]]];
        self.countDownTime = (int)[pfObject[@"expirationDate"] timeIntervalSinceDate:[NSDate date]];
        
    }
    return self;
}

-(void)startTimer{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerCalled:) userInfo:nil repeats:YES];
    }
}

-(void)timerCalled:(NSTimer *)timer{
    if (self.countDownTime == 0) {
        [_timer invalidate];
        _timer = nil;
        [self.delegate statusObjectTimeUpWithObject:self];
    }else{
        self.countDownTime -=1;
        [self.delegate statusObjectTimerCount:self.countDownTime withStatusObject:self];
    }
    
//    if ([self.countDownMessage isEqualToString:@"0"]) {
//        [_timer invalidate];
//        _timer = nil;
//        [self.delegate statusObjectTimeUpWithObject:self];
//        
//    }else{
//        self.countDownMessage = [NSString stringWithFormat:@"%d",self.countDownMessage.intValue - 1];
//        [self.delegate statusObjectTimerCount:self.countDownMessage.intValue-1 withStatusObject:self];
//    }
}

//-(NSString *)description{
//    return [NSString stringWithFormat:@"message %@\ncreatedAt %@\nupdatedAt %@\navatar %@\nuserId %@\npicture %@\nexpirationTimeInSec %@",
//            self.pfObject[@"message"],self.pfObject[@"createdAt"],self.pfObject[@"updatedAt"],self.pfObject[@"avatar"],self.pfObject[@"userId"],self.pfObject[@"picture"],self.pfObject[@"expirationTimeInSec"]];
//}

@end
