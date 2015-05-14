//
//  AppDelegate.m
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    AuthService *authService = [[AuthService alloc] initWithLaunchOptions:launchOptions];
    [authService configure];
    
    return YES;
}

//handles oauth login validation success
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [AuthService handleAuthUrl:url];
    return YES;
}

-(void) presentHomepage {
    BOOL isLoggedIn = [AuthService isUserAuthenticated];
    
    NSString *storyboardId = isLoggedIn ? @"HomeView" : @"LoginView";
    self.window.rootViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:storyboardId];
}

@end
