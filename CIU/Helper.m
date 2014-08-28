//
//  Helper.m
//  CIU
//
//  Created by Sihang on 8/21/14.
//  Copyright (c) 2014 Huang, Jason. All rights reserved.
//

#import "Helper.h"
#import "FPLogger.h"
static Helper *_helper;
@implementation Helper
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

+(MKCoordinateRegion)fetchDataRegionWithCenter:(CLLocationCoordinate2D)center{
    //1 mile = 1609 meters
    //fetch a raidus of 30 miles. we set a fetch limit already so this is OK
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(center, 30*1609, 30*1609);
    return region;
}
@end
