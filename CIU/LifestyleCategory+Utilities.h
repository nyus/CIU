//
//  LifestyleCategory+Utilities.h
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleCategory.h"

typedef NS_ENUM(NSInteger, DDCategoryType) {
    DDCategoryTypeNone,
    DDCategoryTypeRestaurant,
    DDCategoryTypeSupermarket,
    DDCategoryTypeJob,
    DDCategoryTypeTradeAndSell
};

@class PFObject;

@interface LifestyleCategory (Utilities)

+ (NSString *)nameForCategoryType:(DDCategoryType)categoryType;
+ (DDCategoryType)typeForCategoryName:(NSString *)categoryName;
+ (NSString *)getParseClassNameForCategoryType:(DDCategoryType)categoryType;
-(void)populateFromParseojbect:(PFObject *)parseObject;

@end
