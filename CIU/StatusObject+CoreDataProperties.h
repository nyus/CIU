//
//  StatusObject+CoreDataProperties.h
//  
//
//  Created by Sihang on 9/29/15.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StatusObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface StatusObject (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *anonymous;
@property (nullable, nonatomic, retain) NSString *avatar;
@property (nullable, nonatomic, retain) NSNumber *commentCount;
@property (nullable, nonatomic, retain) NSDate *createdAt;
@property (nullable, nonatomic, retain) NSNumber *isBadContent;
@property (nullable, nonatomic, retain) NSNumber *isBadContentLocal;
@property (nullable, nonatomic, retain) NSNumber *isStickyPost;
@property (nullable, nonatomic, retain) NSNumber *latitude;
@property (nullable, nonatomic, retain) NSNumber *likeCount;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSString *message;
@property (nullable, nonatomic, retain) NSString *objectId;
@property (nullable, nonatomic, retain) NSNumber *photoCount;
@property (nullable, nonatomic, retain) NSString *photoID;
@property (nullable, nonatomic, retain) NSString *picture;
@property (nullable, nonatomic, retain) NSString *posterFirstName;
@property (nullable, nonatomic, retain) NSString *posterLastName;
@property (nullable, nonatomic, retain) NSString *posterUsername;
@property (nullable, nonatomic, retain) NSNumber *statusCellHeight;
@property (nullable, nonatomic, retain) NSData *imageData;
@property (nullable, nonatomic, retain) NSNumber *isFetchingImage;

@end

NS_ASSUME_NONNULL_END
