//
//  AuthService.h
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXOAuth2.h"
#import "AppDelegate.h"
#import "DeviceService.h"

@interface AuthService : NSObject

-(id)initWithLaunchOptions:(NSDictionary *)launchOptions;
-(void)configure;

+(BOOL)isUserAuthenticated;

+(NXOAuth2Account*)getClientAccount;
+(NXOAuth2Account*)getUserAccount;
+(void)logout;
+(void)requestUserAccess:(void (^)(NSURL *preparedUrl))authHandler;

+ (void)handleAuthUrl:(NSURL *)url;

@end
