//
//  PFFile+Utilities.h
//  DaDa
//
//  Created by Sihang on 8/21/15.
//  Copyright (c) 2015 Huang, Sihang. All rights reserved.
//

#import "PFFile.h"

@interface PFFile (Utilities)

- (void)fetchImageWithCompletionBlock:(void(^)(BOOL completed, NSData *data))completion;

@end
