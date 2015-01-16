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
#import "GAI.h"
#import "Flurry.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Flurry
#if DEBUG
    [Flurry startSession:@"9W335FKZYV68CQJ7XRJ3"];
#else
    [Flurry startSession:@"3S54CK7JG9Q8DDGVB668"];
#endif

    // Google analytics
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker. Replace with your tracking ID.
    [[GAI sharedInstance] trackerWithTrackingId:@"UA-58518621-1"];
    
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
