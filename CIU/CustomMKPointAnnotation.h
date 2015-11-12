//
//  CustomMKPointAnnotation.h
//  CIU
//
//  Created by Sihang on 8/23/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import <MapKit/MapKit.h>
@class LifestyleObject;
@interface CustomMKPointAnnotation : MKPointAnnotation
@property (nonatomic) BOOL needAnimation;
@property (nonatomic, strong) LifestyleObject *lifetstyleObject;
@end
