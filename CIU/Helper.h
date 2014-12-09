//
//  Helper.h
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
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
+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center radius:(NSNumber *)radius;
+(NSMutableArray *)fetchLocalPostImagesWithGenericPhotoID:(NSString *)photoId totalCount:(int)totalCount isHighRes:(BOOL)isHighRes;
//image processing
+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size;

//map category names displayed in the app to what's on parse. so that when decide to change the display name, the backend wont be affected
+(NSString *)getParseClassNameForCategoryName:(NSString *)categoryName;

//access user location
+(NSDictionary *)userLocation;

//cllocation manager
+(CLLocationManager *)initLocationManagerWithDelegate:(id<CLLocationManagerDelegate>)delegate;
@end
