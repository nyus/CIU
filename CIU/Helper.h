//
//  Helper.h
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@interface Helper : NSObject
+(UIImage *)getLocalImageWithName:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(void)saveImageToLocal:(NSData *)data forImageName:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(BOOL)isLocalImageExist:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center;
@end
