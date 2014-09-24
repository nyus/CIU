//
//  Helper.m
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Helper.h"
#import "FPLogger.h"
#import <Parse/Parse.h>
static Helper *_helper;
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
+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center radius:(int)miles{
    //1 mile = 1609 meters
    //fetch a raidus of 30 miles. we set a fetch limit already so this is OK
    if (miles<=0) {
        miles = 30;
    }
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, miles*1609, miles*1609);
    return region;
}

#pragma mark - image processing

+(UIImage *)scaleImage:(UIImage *)image downToSize:(CGSize) size{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    CGRect imageRect;
    if(image.size.width<image.size.height){
        //handle portrait photos
        float newWidth = image.size.width * size.height/image.size.height;
        imageRect = CGRectMake((size.width-newWidth)/2, 0.0, newWidth, size.height);
    }else{
        imageRect = CGRectMake(0.0, 0.0, size.width, size.height);
    }
    [image drawInRect:imageRect];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

#pragma mark - map display category name to parse class name
+(NSString *)getParseClassNameForCategoryName:(NSString *)categoryName{
    if ([categoryName isEqualToString:@"Restaurant"]) {
        return @"Restaurant";
    }else if ([categoryName isEqualToString:@"Supermarket"]){
        return @"Supermarket";
    }else if ([categoryName isEqualToString:@"Jobs"]){
        return @"Job";
    }else if ([categoryName isEqualToString:@"Trade and Sell"]){
        return @"Trade";
    }else{
        return nil;
    }
}

@end
