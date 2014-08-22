//
//  Helper.m
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

/**
Photo Object: name(String) status(PFObject) username(String) file(PFFile) isHighRes(BOOL) position(Number->0,1,2, for avatar only)
For Posts: 
 whereKey:status equals:status
 whereKey:isHighRes equals:isHighres
 
For Profile:
 whereKey:user equals:user
 whereKey:isHighRes equals:isHighres
 sortByKey:position(optional)
 **/


#import "Query.h"
#import <Parse/Parse.h>
#import "FPLogger.h"
#import "Helper.h"
@interface Query()
@property (nonatomic, strong) PFFile *fileRequest;
@property (nonatomic, strong) PFQuery *query;
@end
@implementation Query


-(void)cancelRequest{
    [self.fileRequest cancel];
    [self.query cancel];
}

-(void)getServerImageWithName:(NSString *)imageName isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock{
    self.query = nil;
    self.query = [[PFQuery alloc] initWithClassName:@"Photo"];
    [self.query whereKey:@"imageName" equalTo:imageName];
    [self.query whereKey:@"isHighRes" equalTo:[NSNumber numberWithBool:isHighRes]];
    
    [self.query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error && object) {
            
            self.fileRequest = (PFFile *)object[@"image"];
            [self.fileRequest getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (data && !error) {
                    UIImage *image = [UIImage imageWithData:data];
                    completionBlock(error, image);
                    //save image to local
                    [Helper saveImageToLocal:data forImageName:imageName isHighRes:isHighRes];
                    
                }else{
                    [FPLogger record:[NSString stringWithFormat:@"error (%@) getting avatar of user %@",error.localizedDescription,imageName]];
                    NSLog(@"error (%@) getting avatar of user %@",error.localizedDescription,imageName);
                }
            }];
            
        }else{
            
            [FPLogger record:[NSString stringWithFormat:@"no avater for user %@", imageName]];
            NSLog(@"no avater for user %@",imageName);
        }
    }];
}

-(void)fetchObjectsOfType:(NSString *)type center:(CLLocationCoordinate2D)center radius:(float)radius completion:(void (^)(NSError *, NSArray *))completionBlock{
    self.query = [PFQuery queryWithClassName:type];
}

@end
