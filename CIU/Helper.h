//
//  Helper.h
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@class PFQuery;
@interface Helper : NSObject
//Avatar
+(void)getAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;
+(UIImage *)getLocalAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes;
+(PFQuery *)getServerAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;

+(BOOL)isLocalAvatarExistForUser:(NSString *)username isHighRes:(BOOL)isHighRes;
+(void)saveAvatar:(NSData *)data forUser:(NSString *)username isHighRes:(BOOL)isHighRes;
+(void)saveAvatarToLocal:(NSData *)data forUser:(NSString *)username isHighRes:(BOOL)isHighRes;

+(void)removeAvatarWithAvatar;
//local image
+(UIImage *)getLocalImageWithName:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(void)saveImageToLocal:(NSData *)data forImageName:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(BOOL)isLocalImageExist:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center;

//image processing
+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size;
@end
