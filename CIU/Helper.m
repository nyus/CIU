//
//  Helper.m
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Helper.h"
#import <Parse/Parse.h>
#import "Event.h"
#import "LifestyleObject.h"
#import "StatusObject.h"

#define Default_Radius 5

static Helper *_helper;
static UIImagePickerController *_imagePicker;
static NSString *kAnonymousAvatarKey = @"kAnonymousAvatarKey";
static int kTotalAnonymousAvatarCount = 149;
static UIImage *anonymousAvatarImage = nil;
static NSTimeInterval kThirtyMins = 1800.0;
static CGFloat kHighestScreenScale = 3.0;
static NSString *const kEventClassName = @"kEventClassName";
static NSString *const kStatusClassName = @"kStatusClassName";
static NSString *const kLifeStyleObjectClassName = @"kLifeStyleObjectClassName";

@interface Helper () <UIAlertViewDelegate>

@end

@implementation Helper

+ (NSString *)filePathForUser:(NSString *)username isHighRes:(BOOL)isHighRes
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",username,isHighRes?@"1":@"0"];
    
    return path;
}

+(BOOL)isLocalAvatarExistForUser:(NSString *)username isHighRes:(BOOL)isHighRes{
    
    return [[NSFileManager defaultManager] fileExistsAtPath:[Helper filePathForUser:username
                                                                          isHighRes:isHighRes]];
}

+(UIImage *)getLocalAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes{

    NSString *path = [Helper filePathForUser:username isHighRes:isHighRes];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        //use local saved avatar right away, then see if the avatar has been updated on the server
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
        UIImage *image = [UIImage imageWithData:imageData];
        return image;
    }
    
    return nil;
}

+(PFQuery *)getServerAvatarForUser:(NSString *)username
                         isHighRes:(BOOL)isHighRes
                        completion:(void (^)(NSError *, UIImage *))completionBlock{
    
    NSError *error;
    NSDictionary *attribute = [[NSFileManager defaultManager] attributesOfItemAtPath:[Helper filePathForUser:username
                                                                                                   isHighRes:isHighRes]
                                                                               error:&error];
    
    // Sync with server every 30 minutes
    
    if (attribute && [attribute[NSFileModificationDate] timeIntervalSinceNow] < kThirtyMins) {
        
        return nil;
    }
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:DDAvatarParseClassName];
    [query whereKey:DDUserNameKey
            equalTo:username];
    [query whereKey:DDIsHighResKey
            equalTo:[NSNumber numberWithBool:isHighRes]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error) {
            NSLog(@"Get server avatar failed with error %@", error);
            completionBlock(error, nil);
        } else {
            PFFile *avatar = (PFFile *)object[DDImageKey];
            [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (data && !error) {
                    UIImage *image = [UIImage imageWithData:data];
                    completionBlock(nil, image);
                    //save image to local
                    [Helper saveAvatarToLocal:data
                                      forUser:username
                                    isHighRes:isHighRes];
                    
                }else{
                    [FPLogger record:[NSString stringWithFormat:@"error (%@) getting avatar of user %@",error.localizedDescription,username]];
                    NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,username);
                }
            }];   
        }
    }];
    
    return query;
}

+(void)getAvatarForUser:(NSString *)username
              isHighRes:(BOOL)isHighRes
             completion:(void (^)(NSError *, UIImage *))completionBlock
{
    
    //first fetch local, if not found, fetch from server
    UIImage *image = [Helper getLocalAvatarForUser:username
                                         isHighRes:isHighRes];
    if (image) {
        completionBlock(nil,image);
    }else{
        [Helper getServerAvatarForUser:username
                             isHighRes:isHighRes
                            completion:^(NSError *error, UIImage *image) {
                                completionBlock(error, image);
                            }];
    }
}

//save avatar
+(void)saveAvatarToLocal:(NSData *)data
                 forUser:(NSString *)username
               isHighRes:(BOOL)isHighRes{
    
    dispatch_queue_t queue = dispatch_queue_create("save avatar", NULL);
    dispatch_async(queue, ^{
        NSString *path = [Helper filePathForUser:username
                                       isHighRes:isHighRes];
        [[NSFileManager defaultManager] createFileAtPath:path
                                                contents:data
                                              attributes:@{NSFileModificationDate: [NSDate date]}];
    });
}

+(void)saveAvatar:(NSData *)data
          forUser:(NSString *)username 
        isHighRes:(BOOL)isHighRes completion:(void (^)(BOOL, NSError *))completion
{
    
    [Helper saveAvatarToLocal:data
                      forUser:username
                    isHighRes:isHighRes];
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:DDAvatarParseClassName];
    [query whereKey:DDUserNameKey
            equalTo:username];
    [query whereKey:DDIsHighResKey
            equalTo:[NSNumber numberWithBool:isHighRes]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        
        if (error && error.code != 101) {
            completion (YES, error);
            NSLog(@"Failed to get avatar with error: %@", error);
        } else {
            
            // User first signs up
            
            if (error.code == 101) {
                object = [PFObject objectWithClassName:DDAvatarParseClassName];
                object[DDUserNameKey] = username;
                object[DDIsHighResKey] = @(isHighRes);
            }
            
            PFFile *file = [PFFile fileWithData:data];
            [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    object[DDImageKey] = file;
                    [object saveEventually];
                    completion (YES, nil);
                } else {
                    completion (YES, error);
                }
            }];
        }
    }];
}

+(void)saveImageToLocal:(NSData *)data forImageName:(NSString *)imageName isHighRes:(BOOL)isHighRes{
    NSLog(@"post image name: %@", imageName);
    dispatch_queue_t queue = dispatch_queue_create("save image", NULL);
    dispatch_async(queue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",imageName,isHighRes?@"1":@"0"];
        
        NSError *writeError = nil;
        [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            [FPLogger record:[NSString stringWithFormat:@"-saveImage write self avatar to file error %@",writeError.localizedDescription]];
            NSLog(@"-saveImage write self avatar to file error %@",writeError.localizedDescription);
        }
    });
}

+(NSMutableArray *)fetchLocalPostImagesWithGenericPhotoID:(NSString *)photoId
                                               totalCount:(int)totalCount
                                                isHighRes:(BOOL)isHighRes{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for (int i = totalCount-1; i >= 0; i--) {
        
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%d%@",photoId,i,isHighRes?@"1":@"0"];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            
            //use local saved avatar right away, then see if the avatar has been updated on the server
            
            NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
            UIImage *image = [UIImage imageWithData:imageData];
            [array addObject:image];
        }
    }
    
    return array;
}
//Map
+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center radius:(NSNumber *)radius{
    //1 mile = 1609 meters
    //fetch a raidus of 15 miles. we set a fetch limit already so this is OK
    if (!radius) {
        radius = @Default_Radius;
    }
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, radius.floatValue*1609, radius.floatValue*1609);
    return region;
}

#pragma mark - image processing

+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size
{
    CGSize newSize = CGSizeMake(size.width * kHighestScreenScale, size.height * kHighestScreenScale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - user location

+(NSDictionary *)userLocation{
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userLocation"];
}
#pragma mark - location manager

+(CLLocationManager *)initLocationManagerWithDelegate:(id<CLLocationManagerDelegate>)delegate{
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {

        //UIApplicationOpenSettingsURLString is ios 8
        if (IS_IOS_8 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Access Denied"
                                                            message:@"DaDa would like to access your location information in order to display userful information around you. Please go to Settins and set location access to 'Always'"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Open Settings", nil];
            alert.tag = 1;
            [alert show];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Access Denied"
                                                            message:@"To display information around you, please turn on location services at Settings > Privacy > Location Services"
                                                           delegate:self
                                                  cancelButtonTitle:@"Dismiss"
                                                  otherButtonTitles:nil, nil];
            alert.tag = 2;
            [alert show];
        }
        
        
        return nil;
    } else {
        
        static dispatch_once_t onceToken;
        static CLLocationManager *locationManager;
        dispatch_once(&onceToken, ^{
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = delegate;
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
            
            if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [locationManager requestWhenInUseAuthorization];
            } else {
                [locationManager startUpdatingLocation];
            }
        });
        
        return locationManager;
    }

}

#pragma mark - UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // user wants to open settings app and grant us location service
    if (alertView.tag == 1 && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

#pragma mark - UIImagePicker

+(void)launchCameraInController:(UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)controller{
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if (!_imagePicker) {
            _imagePicker = [[UIImagePickerController alloc] init];
        }
        _imagePicker.delegate = controller;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _imagePicker.allowsEditing = YES;
        _imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        [controller presentViewController:_imagePicker animated:YES completion:nil];
    } else {
        [TSMessage showNotificationInViewController:controller
                                              title:NSLocalizedString(@"Camera Not Supported On This Device", nil)
                                           subtitle:nil
                                               type:TSMessageNotificationTypeError
                                 accessibilityLabel:kCameraNotSupportedAccessibilityLabel];
    }
}

+(void)launchPhotoLibraryInController:(UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate> *)controller{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        if (!_imagePicker) {
            _imagePicker = [[UIImagePickerController alloc] init];
            _imagePicker.delegate = controller;
            _imagePicker.allowsEditing = YES;
        }
        
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [controller presentViewController:_imagePicker animated:YES completion:nil];
    } else {
        [TSMessage showNotificationInViewController:controller
                                              title:NSLocalizedString(@"Photo Gallery Not Supported On This Device", nil)
                                           subtitle:nil
                                               type:TSMessageNotificationTypeError
                                 accessibilityLabel:kPhotoGalleryNotSupportedAccessibilityLabel];
    }
}

+(void)saveChosenPhoto:(UIImage *)photo andSetOnImageView:(UIImageView *)imageView
{
    if (!photo) {
        return;
    }
    //save avatar to local and server. the reason to do it now is becuase we need to associate the avatar with a username
    NSData *highResData = UIImagePNGRepresentation(photo);
    UIImage *scaled = [Helper scaleImage:photo downToSize:imageView.frame.size];
    NSData *lowResData = UIImagePNGRepresentation(scaled);
    //save to both local and server
    [Helper saveAvatar:highResData forUser:[PFUser currentUser].username isHighRes:YES completion:^(BOOL completed, NSError *error) {
        [Helper saveAvatar:lowResData forUser:[PFUser currentUser].username isHighRes:NO completion:nil];
    }];
    
    imageView.image = scaled;
    
    [_imagePicker dismissViewControllerAnimated:YES completion:nil];
}

+ (UIImage *)getAnonymousAvatarImage
{
    int random = rand() % kTotalAnonymousAvatarCount;
    if (!anonymousAvatarImage) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *imageName = [defaults objectForKey:kAnonymousAvatarKey];
        
        if (!imageName) {
            
            imageName = [NSString stringWithFormat:@"aAvatar%d", random];
            [defaults setObject:imageName forKey:kAnonymousAvatarKey];
            [defaults synchronize];
        }
        
        anonymousAvatarImage = [UIImage imageNamed:imageName];
    }
    
    return anonymousAvatarImage;
}

+ (NSString *)getAnonymousAvatarImageNameForUsername:(NSString *)username statusId:(NSString *)statusId
{
    if (!username || !statusId) {
        return nil;
    }
    
    NSString *key = [username stringByAppendingString:statusId];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *imageName = [defaults objectForKey:key];
    if (!imageName) {
        imageName = [Helper randomAnonymousImageName];
        [defaults setObject:imageName forKey:key];
        [defaults synchronize];
    }
    
    return imageName;
}

+ (NSString *)randomAnonymousImageName
{
    int random = rand() % kTotalAnonymousAvatarCount;
    
    for (int i = 0 ; i < (rand() % 21); i++) {
        random = rand() % kTotalAnonymousAvatarCount;
    }
    
    while (random == 0) {
        random = rand() % kTotalAnonymousAvatarCount;
    }
    
    NSLog(@"random number is %d", random);

    return [NSString stringWithFormat:@"aAvatar%d", random];
}

#pragma mark -- Flag

+(void)flagEvent:(Event *)event
{
    [Helper flagObjectWithObjectId:event.objectId
                     withClassName:kEventClassName];
}

+(void)flagStatus:(StatusObject *)status
{
    [Helper flagObjectWithObjectId:status.objectId
                     withClassName:kStatusClassName];
}

+(void)flagLifeStyleObject:(LifestyleObject *)lifeStyleObject
{
    [Helper flagObjectWithObjectId:lifeStyleObject.objectId
                     withClassName:kLifeStyleObjectClassName];
}

+ (void)flagObjectWithObjectId:(NSString *)objectId withClassName:(NSString *)className
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *flaggedObjectArray = [[defaults objectForKey:className] mutableCopy];
    
    if (!flaggedObjectArray) {
        flaggedObjectArray = [NSMutableArray array];
    }
    
    [flaggedObjectArray addObject:objectId];
    [defaults setObject:flaggedObjectArray forKey:className];
    [defaults synchronize];
}

+ (void)createAuditWithObjectId:(NSString *)objectId category:(NSString *)category
{
    PFQuery *query = [PFQuery queryWithClassName:DDAuditParseClassName];
    [query whereKey:DDAuditObjectId equalTo:objectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
        if (!object) {
            PFObject *audit = [PFObject objectWithClassName:DDAuditParseClassName];
            audit[DDAuditObjectId] = objectId;
            audit[DDCategoryKey] = category;
            [audit saveEventually];
        }
    }];
}

+(NSArray *)flaggedEventObjectIds
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *flaggedObjectArray = [defaults objectForKey:kEventClassName];
    
    if (!flaggedObjectArray) {
        return @[];
    }
    
    return flaggedObjectArray;
}

+(NSArray *)flaggedStatusObjectIds
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *flaggedObjectArray = [defaults objectForKey:kStatusClassName];
    
    if (!flaggedObjectArray) {
        return @[];
    }
    
    return flaggedObjectArray;
}

+(NSArray *)flaggedLifeStyleObjectIds
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *flaggedObjectArray = [defaults objectForKey:kLifeStyleObjectClassName];
    
    if (!flaggedObjectArray) {
        return @[];
    }
    
    return flaggedObjectArray;
}

@end
