//
//  NSString+Map.h
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@interface NSString (Map)
+(NSString *)stringFromMKCoordinateRegion:(MKCoordinateRegion)region;
@end
