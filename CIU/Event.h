//
//  Event.h
//  
//
//  Created by Sihang Huang on 9/2/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Event : NSManagedObject

@property (nonatomic, retain) NSNumber * cellHeight;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * eventContent;
@property (nonatomic, retain) NSDate * eventDate;
@property (nonatomic, retain) NSString * eventLocation;
@property (nonatomic, retain) NSString * eventName;
@property (nonatomic, retain) NSNumber * isBadContent;
@property (nonatomic, retain) NSNumber * isStickyPost;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) NSString * senderFirstName;
@property (nonatomic, retain) NSString * senderLastName;
@property (nonatomic, retain) NSString * senderUsername;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSNumber * isBadContentLocal;

@end
