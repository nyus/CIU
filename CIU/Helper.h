//
//  Helper.h
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "LifestyleCategory+Utilities.h"

static const NSInteger EULA_TAG = 50;

@class PFQuery;
@class Event;
@class LifestyleObject;
@class StatusObject;

@interface Helper : NSObject

//Avatar
+(void)getAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;
+(UIImage *)getLocalAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes;
+(PFQuery *)getServerAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;
+(BOOL)isLocalAvatarExistForUser:(NSString *)username isHighRes:(BOOL)isHighRes;

+(void)saveAvatar:(NSData *)data forUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void(^)(BOOL completed, NSError* error))completion;
+(void)saveAvatarToLocal:(NSData *)data forUser:(NSString *)username isHighRes:(BOOL)isHighRes;
+ (NSString *)getAnonymousAvatarImageNameForUsername:(NSString *)username statusId:(NSString *)statusId;
+ (NSString *)randomAnonymousImageName;

//local image
+(void)saveImageToLocal:(NSData *)data forImageName:(NSString *)imageName isHighRes:(BOOL)isHighRes;
+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center radius:(NSNumber *)radius;
+(NSMutableArray *)fetchLocalPostImagesWithGenericPhotoID:(NSString *)photoId totalCount:(int)totalCount isHighRes:(BOOL)isHighRes;

//image processing
+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size;

//access user location
+(NSDictionary *)userLocation;

//cllocation manager
+(CLLocationManager *)initLocationManagerWithDelegate:(id<CLLocationManagerDelegate>)delegate;

//Image picker
+(void)launchCameraInController:(UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)controller;
+(void)launchPhotoLibraryInController:(UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)controller;
+(void)saveChosenPhoto:(UIImage *)photo andSetOnImageView:(UIImageView *)imageView;

//Flag
+(void)flagEvent:(Event *)event;
+(void)flagStatus:(StatusObject *)status;
+(void)flagLifeStyleObject:(LifestyleObject *)lifeStyleObject;
+(void)createAuditWithObjectId:(NSString *)objectId category:(NSString *)category;

//
+(NSArray *)flaggedEventObjectIds;
+(NSArray *)flaggedStatusObjectIds;
+(NSArray *)flaggedLifeStyleObjectIds;

@end
