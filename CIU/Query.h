//
//  Helper.h
//  FastPost
//
//  Created by Sihang Huang on 1/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#define CompletionBlock void(^)(NSError *error, NSArray *results)
@interface Query : NSObject
@property (copy) void (^completion)(NSError *error, UIImage *image);

-(void)cancelRequest;
-(void)getServerImageWithName:(NSString *)imageName isHighRes:(BOOL)isHighRes completion:(void(^)(NSError *error, UIImage *image))completionBlock;

-(void)fetchObjectsOfClassName:(NSString *)type region:(MKCoordinateRegion)region completion:(CompletionBlock)completionBlock;

@end
