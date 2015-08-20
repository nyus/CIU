//
//  Event+Utilities.h
//  CIU
//
//  Created by Sihang on 9/6/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Event.h"
@class PFObject;
@interface Event (Utilities)
-(void)populateFromParseObject:(PFObject *)object;
@end
