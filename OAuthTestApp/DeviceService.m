//
//  DeviceService.m
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import "DeviceService.h"

@implementation DeviceService

//check to see if device has been registered on our servers
+(BOOL)checkRegistration {
    
    NSString *deviceid = [Lockbox stringForKey:@"deviceid"];
    if (deviceid == nil || [deviceid isEqualToString:@"0"] || [deviceid isEqualToString:@""])
    {
        NSNumber *deviceid = [self registerDevice];
        
        if (deviceid == nil || [deviceid isEqual: @""] || [deviceid isEqualToNumber:[NSNumber numberWithInt:0]]) {
            return NO;
        }
        
        [Lockbox setString:[deviceid stringValue] forKey:@"deviceid"];
    }
    
    [self updateInfo];
    
    return YES;
}

+(NSNumber*)getDeviceId
{
    NSString *deviceid = [Lockbox stringForKey:@"deviceid"];
    return [Functions toNumber:deviceid]; //convert to number
}

+(NSNumber*)registerDevice {
    
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *params = @{
                             @"uuid": [[device identifierForVendor] UUIDString],
                             @"appType": @"iOS",
                             @"appVersion": [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]
                             };
    
    DataService *dataService = [[DataService alloc] init];
    id response = [dataService makeSyncRequest:@"Device/Register" method:@"POST" parameters:params useClientAuth:true];
    
    if (response == nil || [response[@"meta"][@"success"] isEqual: @"0"]) {
        return [NSNumber numberWithInt:0];
    }
    
    return [Functions toNumber:response[@"data"]]; //return deviceid from server based on uuid
}

+(void)updateInfo
{
    [self updateDeviceInfo:^(AFHTTPRequestOperation *operation, id response) {
        NSDictionary *info = response[@"data"];
        
        //save any info needed on the status check
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

+(void)updateDeviceInfo:(void (^)(AFHTTPRequestOperation *operation, id response))success
                failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *model = [currentDevice model];
    NSString *systemName = [currentDevice systemName];
    NSString *systemVersion = [currentDevice systemVersion];
    NSString *uuid = [[currentDevice identifierForVendor] UUIDString];
    NSArray *languageArray = [NSLocale preferredLanguages];
    NSString *language = [languageArray objectAtIndex:0];
    NSLocale *locale = [NSLocale currentLocale];
    NSString *country = [locale localeIdentifier];
    NSString *appVersion = [self versionBuild];
    
    NSDictionary *params = @{
                             @"appType":@"iOS",
                             @"appVersion":appVersion,
                             @"systemName":systemName,
                             @"systemVersion":systemVersion,
                             @"model":model,
                             @"language":language,
                             @"country":country,
                             @"uuid":uuid
                             };
    
    DataService *dataService = [[DataService alloc] init];
    [dataService makeRequest:@"Device/UpdateInfo" method:@"POST" parameters:params useClientAuth:true success:success failure:failure];
}

+ (NSString *) versionBuild
{
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    NSString * versionBuild = [NSString stringWithFormat: @"v%@", version];
    
    if (![version isEqualToString: build]) {
        versionBuild = [NSString stringWithFormat: @"%@(%@)", versionBuild, build];
    }
    
    return versionBuild;
}

@end
