//
//  BaseViewControllerWithStatusTableView.m
//  FastPost
//
//  Created by Sihang Huang on 1/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "BaseViewControllerWithStatusTableView.h"
#import <Parse/Parse.h>
#import "Helper.h"
#import "StatusObject.h"
#import "FPLogger.h"
#import "StatusTableViewCell.h"
#import "SpinnerImageView.h"
#define BACKGROUND_CELL_HEIGHT 300.0f
#define ORIGIN_Y_CELL_MESSAGE_LABEL 76.0f
#define CELL_MESSAGE_LABEL_WIDTH 280.0f
#define SPINNER_VIEW_TAG 17
#define CELL_PHOTO_SIZE CGSizeMake(279.0,204.0)
@interface BaseViewControllerWithStatusTableView (){

    //cache calculated label height
    NSMutableDictionary *labelHeightMap;
    //cache is there photo
    NSMutableDictionary *isTherePhotoMap;
    //cache cell height
    NSMutableDictionary *cellHeightMap;
}

@end

@implementation BaseViewControllerWithStatusTableView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    labelHeightMap = [NSMutableDictionary dictionary];
    isTherePhotoMap = [NSMutableDictionary dictionary];
    cellHeightMap = [NSMutableDictionary dictionary];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    for(Status *status in self.dataSource){
        //cancel download
//        [status.picture cancel];
    }
}


#pragma mark - UITableViewDelete

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return self.dataSource.count;
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{   

    StatusObject *status = self.dataSource[indexPath.row];

    __block StatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageAndPhotoCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.delegate = self;
    //pass a reference so in statusTableViewCell can use status.hash to access stuff
//    cell.status = status;
    
    //message
    cell.statusCellMessageLabel.text = status.message;
    
    //username
    cell.statusCellUsernameLabel.text = status.posterUsername;
    cell.userNameButton.titleLabel.text = status.posterUsername;//need to set this text! used to determine if profile VC is displaying self profile or not
    [cell.avatarButton setTitle:status.posterUsername forState:UIControlStateNormal];

    //cell date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm MM/dd/yy"];
    NSString *str = [formatter stringFromDate:status.createdAt];
    cell.statusCellDateLabel.text = str;
    
    //comment count
    cell.commentCountLabel.text = status.commentCount.stringValue;
    

    // Only load cached images; defer new downloads until scrolling ends. if there is no local cache, we download avatar in scrollview delegate methods
    cell.statusCellAvatarImageView.image = [UIImage imageNamed:@"default-user-icon-profile.png"];
//    UIImage *avatar = [Helper getLocalAvatarForUser:status.posterUsername avatarType:AvatarTypeMid isHighRes:NO];
//    if (avatar) {
//        cell.statusCellAvatarImageView.image = avatar;
//    }else{
//        if (tableView.isDecelerating == NO && tableView.isDragging == NO) {
//            [Helper getServerAvatarForUser:status.posterUsername avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
//                cell.statusCellAvatarImageView.image = image;
//            }];
//        }
//    }
    
    //get post image
    if(status.photoCount.intValue>0){
        cell.collectionView.dataSource = cell;
        if (cell.collectionViewImagesArray!=nil) {
            [cell.collectionView reloadData];
        }else if (tableView.isDecelerating == NO && tableView.isDragging == NO){
            [self getServerPostImageForCellAtIndexpath:indexPath];
        }
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 200;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return BACKGROUND_CELL_HEIGHT;
    }else{
        
        StatusObject *status = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)status.hash];

        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
            
            return [[cellHeightMap objectForKey:key] floatValue];
            
        }else{
            
            //determine height of label(message must exist)
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 20)];
            //number of lines must be set to zero so that sizeToFit would work correctly
            label.numberOfLines = 0;
            label.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:17];
            label.text = [status message];
            CGSize aSize = [label sizeThatFits:label.frame.size];

            float labelHeight = aSize.height;//ceilf(ceilf(size.width) / CELL_MESSAGE_LABEL_WIDTH)*ceilf(size.height)+10;
            [labelHeightMap setObject:[NSNumber numberWithFloat:labelHeight] forKey:key];
            
            
            //determine if there is a picture
            float pictureHeight = 0;;
            NSNumber *photoCount = status.photoCount;
            if (photoCount.intValue==0) {
                
                [isTherePhotoMap setObject:[NSNumber numberWithBool:NO] forKey:key];
                pictureHeight = 0;
                
            }else{
                //204 height of picture image view
                [isTherePhotoMap setObject:[NSNumber numberWithBool:YES] forKey:key];
                pictureHeight = 204;
                
            }
            
            float cellHeight = ORIGIN_Y_CELL_MESSAGE_LABEL + labelHeight;
            if (pictureHeight !=0) {
                cellHeight += 10 + pictureHeight;
            }
            
            cellHeight = cellHeight+10;
            
            [cellHeightMap setObject:[NSNumber numberWithFloat:cellHeight]
                              forKey:key];
            return cellHeight;
        }
    }
}

-(void)removeStoredHeightForStatus:(StatusObject *)status{
    NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)status.hash];
    [cellHeightMap removeObjectForKey:key];
}

#pragma mark - uiscrollview delegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self loadImagesForOnscreenRows];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

- (void)loadImagesForOnscreenRows
{
#warning 
//    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
//    for (NSIndexPath *indexPath in visiblePaths)
//    {
//        __block StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//        Status *status = self.dataSource[indexPath.row];
//        
//        BOOL avatar = [Helper isLocalAvatarExistForUser:status.posterUsername avatarType:AvatarTypeMid isHighRes:NO];
//        if (!avatar) {
//            [Helper getServerAvatarForUser:status.posterUsername avatarType:AvatarTypeMid isHighRes:NO completion:^(NSError *error, UIImage *image) {
//                cell.statusCellAvatarImageView.image = image;
//            }];
//        }
//        
//        
//        if (cell.collectionViewImagesArray==nil && status.photoCount.intValue!=0) {
//            [self getServerPostImageForCellAtIndexpath:indexPath];
//        }
//    }
}

-(void)getServerPostImageForCellAtIndexpath:(NSIndexPath *)indexPath{
#warning 
//    __block StatusTableViewCell *cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//    [cell.statusCellPhotoImageView showLoadingActivityIndicator];
//    Status *status = self.dataSource[indexPath.row];
//    
//    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Photo"];
//    [query whereKey:@"status" equalTo:status.pfObject];
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        if (!error && objects.count!=0) {
//            if (cell==nil) {
//                cell = (StatusTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//            }
//            for (PFObject *photoObject in objects) {
//                PFFile *image = photoObject[@"image"];
//                [image getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
//                    if (!error) {
//                        NSLog(@"add items for indexpath %@",indexPath);
//                        
//                        UIImage *image = [UIImage imageWithData:data];
//                        if (!cell.collectionViewImagesArray) {
//                            cell.collectionViewImagesArray = [NSMutableArray array];
//                        }
//                        NSLog(@"add photo for indexpath: %@",indexPath);
//                        [cell.collectionViewImagesArray addObject:image];
//                        [cell.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:cell.collectionViewImagesArray.count-1 inSection:0]]];
//                    }
//                }];
//            }
//        }
//    }];
}

@end
