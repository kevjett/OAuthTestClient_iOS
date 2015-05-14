//
//  DataService.m
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import "DataService.h"

static BOOL extra_debug_on = NO;
//static BOOL extra_debug_on = YES;

@interface DataService ()
    @property (readwrite, nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation DataService

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.operationQueue = [[NSOperationQueue alloc] init];
    [self.operationQueue setMaxConcurrentOperationCount:4];
    
    return self;
}

+ (NSString*)getServerUrl
{
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat:@"https://%@", [info objectForKey:@"API_URL"]];
}

- (NSURLRequest *)requestWithUrl:(NSString *)url
                          method:(NSString *)method
                      parameters:(NSDictionary *)parameters
                   useClientAuth:(BOOL)useClientAuth {
    
    if (parameters == nil) {
        parameters = @{};
    }
    
    //make sure to always send device id as a parameter so we will always have it if needed
    if (parameters[@"deviceId"] == nil) {
        NSNumber *deviceid = [DeviceService getDeviceId];
        if (deviceid != nil) {
            NSMutableDictionary *tmp = [[NSMutableDictionary alloc] initWithDictionary:parameters];
            tmp[@"deviceId"] = [deviceid stringValue];
            parameters = tmp;
        }
    }
    
    NXOAuth2Request *theRequest = [[NXOAuth2Request alloc] initWithResource:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [DataService getServerUrl], url]]
                                                                     method:method
                                                                 parameters:parameters];
    
    
    
    
    theRequest.account = useClientAuth ? [AuthService getClientAccount] : [AuthService getUserAccount];
    NSURLRequest *sigendRequest = [theRequest signedURLRequest];
    
    return sigendRequest;
}

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request
                                                    success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                                    failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    
    
    void (^xmlrpcSuccess)(AFHTTPRequestOperation *, id) = ^(AFHTTPRequestOperation *operation, id responseObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            NSError *err = nil;
            if ( extra_debug_on == YES ) {
                NSLog(@"[DataService:Response] < %@", operation.responseString);
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (err) {
                    if (failure) {
                        failure(operation, err);
                    }
                } else {
                    if (success) {
                        success(operation, responseObject);
                    }
                }
            });
        });
    };
    void (^xmlrpcFailure)(AFHTTPRequestOperation *, NSError *) = ^(AFHTTPRequestOperation *operation, NSError *error) {
        if ( extra_debug_on == YES ) {
            NSLog(@"[DataService] ! %@", [error localizedDescription]);
        }
        
        if ([[error.userInfo objectForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: unauthorized (401)"])
        {
            NSLog(@"[Authorization Failed] ! %@", [error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                                                                                  error, NXOAuth2AccountStoreErrorKey, nil]];
            
            return;
        }
        
        if (failure) {
            failure(operation, error);
        }
    };
    
    if ( extra_debug_on == YES ) {
        NSString *requestString = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
        NSLog(@"[DataService:Request] > %@", requestString);
    }
    
    [operation setCompletionBlockWithSuccess:xmlrpcSuccess failure:xmlrpcFailure];
    
    return operation;
}

#pragma mark - Managing Enqueued HTTP Operations

- (void)enqueueHTTPRequestOperation:(AFHTTPRequestOperation *)operation {
    [self.operationQueue addOperation:operation];
}

- (void)cancelAllHTTPOperations {
    for (AFHTTPRequestOperation *operation in [self.operationQueue operations]) {
        [operation cancel];
    }
}

- (void)makeRequest:(NSString *)url
             method:(NSString *)method
         parameters:(NSDictionary *)parameters
            success:(void (^)(AFHTTPRequestOperation *operation, id response))success
            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [self makeRequest:url method:method parameters:parameters useClientAuth:false success:success failure:failure];
}

- (void)makeRequest:(NSString *)url
             method:(NSString *)method
         parameters:(NSDictionary *)parameters
      useClientAuth:(BOOL)useClientAuth
            success:(void (^)(AFHTTPRequestOperation *operation, id response))success
            failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    
    NSURLRequest *request = [self requestWithUrl:url method:method parameters:parameters useClientAuth:useClientAuth];
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(operation, responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(operation, error);
    }];
    
    [self enqueueHTTPRequestOperation:operation];
}

- (id)makeSyncRequest:(NSString *)url
               method:(NSString *)method
           parameters:(NSDictionary *)parameters {
    return [self makeSyncRequest:url method:method parameters:parameters useClientAuth:false];
}

- (id)makeSyncRequest:(NSString *)url
               method:(NSString *)method
           parameters:(NSDictionary *)parameters
        useClientAuth:(BOOL)useClientAuth
{
    NSURLRequest *request = [self requestWithUrl:url method:method parameters:parameters useClientAuth:useClientAuth];
    
    NSError *error;
    
    NSURLResponse *response;
    
    if ( extra_debug_on == YES ) {
        NSLog(@"[DataService:Request] < %@", request);
    }
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request   returningResponse:&response error:&error];
    
    if ( extra_debug_on == YES ) {
        NSLog(@"[DataService:Response] < %@", response);
    }
    
    if ([[error.userInfo objectForKey:@"NSLocalizedDescription"] isEqualToString:@"Request failed: unauthorized (401)"])
    {
        NSLog(@"[Authorization Failed] ! %@", [error localizedDescription]);
        [[NSNotificationCenter defaultCenter] postNotificationName:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                                                                                              error, NXOAuth2AccountStoreErrorKey, nil]];
        
        return nil;
    }
    
    NSError* jsonerror;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:kNilOptions
                                                           error:&jsonerror];
    return json;
}

@end





