//
//  DataService.h
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "NXOAuth2.h"
#import "DeviceService.h"
#import "AuthService.h"

@interface DataService : NSObject

@property (readonly, nonatomic, strong) NSOperationQueue *operationQueue;

- (void)makeRequest:(NSString *)url
             method:(NSString *)method
         parameters:(NSDictionary *)parameters
            success:(void (^)(AFHTTPRequestOperation *operation, id response))success
            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)makeRequest:(NSString *)url
             method:(NSString *)method
         parameters:(NSDictionary *)parameters
      useClientAuth:(BOOL)useClientAuth
            success:(void (^)(AFHTTPRequestOperation *operation, id response))success
            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (id)makeSyncRequest:(NSString *)url
               method:(NSString *)method
           parameters:(NSDictionary *)parameters;
- (id)makeSyncRequest:(NSString *)url
               method:(NSString *)method
           parameters:(NSDictionary *)parameters
        useClientAuth:(BOOL)useClientAuth;

@end
