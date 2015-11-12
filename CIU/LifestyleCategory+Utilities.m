//
//  LifestyleCategory+Utilities.m
//  CIU
//
//  Created by Sihang on 8/20/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "LifestyleCategory+Utilities.h"
#import <Parse/Parse.h>

static NSString *const kJobName = @"Jobs";
static NSString *const kRestaurantName = @"Restaurant";
static NSString *const kSupermarketName = @"Supermarket";
static NSString *const kTradeAndSellName = @"Trade and Sell";

static NSString *const kJobParseClassName = @"Jobs";
static NSString *const kRestaurantParseClassName = @"Restaurant";
static NSString *const kSupermarketParseClassName = @"Supermarket";
static NSString *const kTradeAndSellParseClassName = @"Trade";

@implementation LifestyleCategory (Utilities)

+ (NSString *)nameForCategoryType:(DDCategoryType)categoryType
{
    switch (categoryType) {
        case DDCategoryTypeJob:
            return kJobName;
            break;
        case DDCategoryTypeRestaurant:
            return kRestaurantName;
            break;
        case DDCategoryTypeSupermarket:
            return kSupermarketName;
            break;
        case DDCategoryTypeTradeAndSell:
            return kTradeAndSellName;
            break;
        default:
            return nil;
            break;
    }
}

+ (DDCategoryType)typeForCategoryName:(NSString *)categoryName
{
    if ([categoryName isEqualToString:kJobName]) {
        return DDCategoryTypeJob;
    } else if ([categoryName isEqualToString:kRestaurantName]) {
        return DDCategoryTypeRestaurant;
    } else if ([categoryName isEqualToString:kSupermarketName]) {
        return DDCategoryTypeSupermarket;
    } else if ([categoryName isEqualToString:kTradeAndSellName]) {
        return DDCategoryTypeTradeAndSell;
    } else {
        return DDCategoryTypeNone;
    }
}

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

+ (NSString *)getParseClassNameForCategoryType:(DDCategoryType)categoryType
{
    switch (categoryType) {
        case DDCategoryTypeJob:
            return kJobParseClassName;
            break;
        case DDCategoryTypeRestaurant:
            return kRestaurantParseClassName;
            break;
        case DDCategoryTypeSupermarket:
            return kSupermarketParseClassName;
            break;
        case DDCategoryTypeTradeAndSell:
            return kTradeAndSellParseClassName;
            break;
        default:
            return nil;
            break;
    }
}

-(void)populateFromParseojbect:(PFObject *)parseObject{
    self.objectId = parseObject.objectId;
    self.createdAt = parseObject.createdAt;
    self.updatedAt = parseObject.updatedAt;
    self.name = parseObject[@"name"];
    self.importance = parseObject[@"importance"];
}

@end
