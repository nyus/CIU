//
//  AppDelegate.m
//  CIU
//
//  Created by Huang, Sihang on 8/14/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "AppDelegate.h"
#import "LocationManager.h"
#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
#if DEBUG
    [Parse setApplicationId:@"5iuZZ1iDu1brQG79t8VXWbztxRWFprDUx22zEAxl"
                  clientKey:@"L2o6bd1AbEOBgmYJMaJJOH8xxb8VW4VcC0lNZJ2b"];
#else
    [Parse setApplicationId:@"dREZy34PedC54NzkwKdzw9InfmkPFCZ3kNmj8TNB"
                  clientKey:@"urvgpguNb8wja2nX8wyHe5h8SfD0DCQB7WdTZSZg"];
#endif
    [PFFacebookUtils initializeFacebook];
    return YES;
}

// ****************************************************************************
// App switching methods to support Facebook Single Sign-On.
// ****************************************************************************
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
    
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [[PFFacebookUtils session] close];
}
@end
