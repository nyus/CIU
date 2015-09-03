//
//  LifestyleObject.h
//  
//
//  Created by Sihang Huang on 9/2/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LifestyleObject : NSManagedObject

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) id hours;
@property (nonatomic, retain) NSString * introduction;
@property (nonatomic, retain) NSNumber * isBadContent;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSString * website;
@property (nonatomic, retain) NSNumber * isBadContentLocal;

@end
