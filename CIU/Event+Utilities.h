//
//  Event+Utilities.h
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Event.h"
@class PFObject;
@interface Event (Utilities)
-(void)populateFromParseojbect:(PFObject *)object;
@end
