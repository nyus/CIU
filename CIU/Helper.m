//
//  Helper.m
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "Helper.h"
#import <Parse/Parse.h>
#define Default_Radius 5

static Helper *_helper;
static UIImagePickerController *_imagePicker;
static NSString *kAnonymousAvatarKey = @"kAnonymousAvatarKey";
static int kTotalAnonymousAvatarCount = 149;
static UIImage *anonymousAvatarImage = nil;

@interface Helper () <UIAlertViewDelegate>

@end

@implementation Helper
//Avatar
//get avatar
+(BOOL)isLocalAvatarExistForUser:(NSString *)username isHighRes:(BOOL)isHighRes{
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",username,isHighRes?@"1":@"0"];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+(UIImage *)getLocalAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes{
    
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",username,isHighRes?@"1":@"0"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        //use local saved avatar right away, then see if the avatar has been updated on the server
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
        UIImage *image = [UIImage imageWithData:imageData];
        return image;
    }
    
    return nil;
}

+(PFQuery *)getServerAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void (^)(NSError *, UIImage *))completionBlock{
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"username" equalTo:username];
    [query whereKey:@"isHighRes" equalTo:[NSNumber numberWithBool:isHighRes]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            
            PFFile *avatar = (PFFile *)object[@"image"];
            [avatar getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (data && !error) {
                    UIImage *image = [UIImage imageWithData:data];
                    completionBlock(error, image);
                    //save image to local
                    [Helper saveAvatarToLocal:data forUser:username isHighRes:isHighRes];
                    
                }else{
                    [FPLogger record:[NSString stringWithFormat:@"error (%@) getting avatar of user %@",error.localizedDescription,username]];
                    NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,username);
                }
            }];
            
        }else{
            
            [FPLogger record:[NSString stringWithFormat:@"no avater for user %@", username]];
            NSLog(@"no avater for user %@",username);
        }
    }];
    
    return query;
}

+(void)getAvatarForUser:(NSString *)username isHighRes:(BOOL)isHighRes completion:(void (^)(NSError *, UIImage *))completionBlock{
    
    //first fetch local, if not found, fetch from server
    UIImage *image = [Helper getLocalAvatarForUser:username isHighRes:isHighRes];
    if (image) {
        completionBlock(nil,image);
    }else{
        [Helper getServerAvatarForUser:username isHighRes:isHighRes completion:^(NSError *error, UIImage *image) {
            completionBlock(error, image);
        }];
    }
}

//save avatar
+(void)saveAvatarToLocal:(NSData *)data forUser:(NSString *)username isHighRes:(BOOL)isHighRes{
    
    dispatch_queue_t queue = dispatch_queue_create("save avatar", NULL);
    dispatch_async(queue, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = paths[0];
        NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",username,isHighRes?@"1":@"0"];
        
        NSError *writeError = nil;
        [data writeToFile:path options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            [FPLogger record:[NSString stringWithFormat:@"-saveAvatar write self avatar to file error %@",writeError.localizedDescription]];
            NSLog(@"-saveAvatar write self avatar to file error %@",writeError.localizedDescription);
        }
    });
    
}

+(void)saveAvatar:(NSData *)data forUser:(NSString *)username isHighRes:(BOOL)isHighRes{
    
    [Helper saveAvatarToLocal:data forUser:username isHighRes:isHighRes];
    
    PFFile *file = [PFFile fileWithData:data];
    [file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            
            PFObject *object = [PFObject objectWithClassName:@"Photo"];
            [object setObject:username forKey:@"username"];
            [object setObject:file forKey:@"image"];
            [object setObject:[NSNumber numberWithBool:isHighRes] forKey:@"isHighRes"];
            [object saveEventually];
        }
    }];
}

//only the currentUser can delete avatar
+(void)removeAvatarWithAvatar{
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [query whereKey:@"username" equalTo:[PFUser currentUser].username];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects.count!=0) {
            for (PFObject *object in objects) {
                [object deleteInBackground];
            }
        }
    }];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",[PFUser currentUser].username,@"1"];
    NSError *error;
    //remove high res
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    //remove low res
    path = [documentDirectory stringByAppendingFormat:@"/%@%@",[PFUser currentUser].username,@"0"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
}

//Local image
+(UIImage *)getLocalImageWithName:(NSString *)imageName isHighRes:(BOOL)isHighRes{
    
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",imageName,isHighRes?@"1":@"0"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        //use local saved avatar right away, then see if the avatar has been updated on the server
        NSData *imageData = [[NSFileManager defaultManager] contentsAtPath:path];
        UIImage *image = [UIImage imageWithData:imageData];
        return image;
    }
    
    return nil;
}

+(BOOL)isLocalImageExist:(NSString *)imageName isHighRes:(BOOL)isHighRes{
    //if user avatar is saved, pull locally; otherwise pull from server and save it locally
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    NSString *path = [documentDirectory stringByAppendingFormat:@"/%@%@",imageName,isHighRes?@"1":@"0"];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

+(void)saveImageToLocal:(NSData *)data forImageName:(NSString *)imageName isHighRes:(BOOL)isHighRes{
    
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

+(NSMutableArray *)fetchLocalPostImagesWithGenericPhotoID:(NSString *)photoId totalCount:(int)totalCount isHighRes:(BOOL)isHighRes{
    NSMutableArray *array = [NSMutableArray array];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = paths[0];
    for (int i=totalCount-1; i>=0; i--) {
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

+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size{
    
    CGRect imageRect;
    if(image.size.width<image.size.height){
        //handle portrait photos
        float newWidth = image.size.width * size.height/image.size.height;
        imageRect = CGRectMake(0.0, 0.0, newWidth, size.height);
    }else{
        imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
    }
    
    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0.0f);
    [image drawInRect:imageRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
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
    [Helper saveAvatar:highResData forUser:[PFUser currentUser].username isHighRes:YES];
    [Helper saveAvatar:lowResData forUser:[PFUser currentUser].username isHighRes:NO];
    
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
    /* initialize random seed: */
    srand((int)time(NULL));
    int random = rand() % kTotalAnonymousAvatarCount;
    while (random == 0) {
        random = rand() % kTotalAnonymousAvatarCount;
    }

    return [NSString stringWithFormat:@"aAvatar%d", random];
}

@end
