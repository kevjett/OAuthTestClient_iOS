//
//  DeviceService.h
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Lockbox.h"
#import "DataService.h"
#import "Functions.h"

@interface DeviceService : NSObject

+(BOOL)checkRegistration;
+(NSNumber*)getDeviceId;

@end
