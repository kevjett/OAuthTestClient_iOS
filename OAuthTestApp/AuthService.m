//
//  AuthService.m
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import "AuthService.h"

static NSString *userauth_account_name = @"AppUser";
static NSString *clientauth_account_name = @"AppClient";

@interface AuthService()
@property (readonly) NSDictionary *launchOptions;
@end

@implementation AuthService

- (id)initWithLaunchOptions:(NSDictionary *)launchOptions {
    self = [super init];
    if (self) {
        _launchOptions = launchOptions;
    }
    return self;
}


- (void)configure {
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    
    //oauth store
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    
    
    //init user oauth
    [store setClientID:[info objectForKey:@"OAUTH_CLIENTID"] // app/client id from resources
                secret:[info objectForKey:@"OAUTH_SECRET"] //app secret key
      authorizationURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/oauth2/Authorize?auto=true", [info objectForKey:@"API_URL"]]] //oauth url for authorization request
              tokenURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/oauth2/Token", [info objectForKey:@"API_URL"]]] //oauth url for token authorization
           redirectURL:[NSURL URLWithString:@"appname://AppName-authcallback"] //custom url pointing back to app to process after authentication
        forAccountType:userauth_account_name];
    
    
    //init client oauth
    [store setClientID:[info objectForKey:@"OAUTH_CLIENTID"]
                secret:[info objectForKey:@"OAUTH_SECRET"]
      authorizationURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/oauth2/Authorize?auto=true", [info objectForKey:@"API_URL"]]]
              tokenURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/oauth2/Token", [info objectForKey:@"API_URL"]]]
           redirectURL:[NSURL URLWithString:@"appname://AppName-authcallback"]
        forAccountType:clientauth_account_name];
    
    
    //fix issue with content type not getting set on requests
    NSDictionary *contentTypeHeader = @{ @"Content-Type": @"application/x-www-form-urlencoded" };
    NSDictionary *customHeaders = @{ kNXOAuth2AccountStoreConfigurationCustomHeaderFields : contentTypeHeader };
    
    //scope for authentication
    NSDictionary *scope = @{ kNXOAuth2AccountStoreConfigurationScope : [NSSet setWithObjects:@"manage", @"web", nil] };
    
    //update config for user auth
    NSDictionary *configuration = [store configurationForAccountType:userauth_account_name];
    NSMutableDictionary *updatedConfig = [[NSMutableDictionary alloc] initWithDictionary:configuration];
    [updatedConfig addEntriesFromDictionary:customHeaders];
    [updatedConfig addEntriesFromDictionary:scope];
    [store setConfiguration:updatedConfig forAccountType:userauth_account_name];
    
    
    //update config for client auth
    configuration = [store configurationForAccountType:clientauth_account_name];
    updatedConfig = [[NSMutableDictionary alloc] initWithDictionary:configuration];
    [updatedConfig addEntriesFromDictionary:customHeaders];
    [updatedConfig addEntriesFromDictionary:scope];
    [store setConfiguration:updatedConfig forAccountType:clientauth_account_name];
    
    
    //setup event when new authorization
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:store
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSLog(@"AccountStoreAccountsDidChangeNotification");
                                                      
                                                      NXOAuth2Account *account = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreNewAccountUserInfoKey];
                                                      
                                                      if (account == nil) {
                                                          return;
                                                      }
                                                      else if ([[account accountType] isEqualToString:userauth_account_name]) {
                                                          //send the user to the dashboard because the user has been authenticated.
                                                          
                                                          //the user is authenticated and you can now request for more info about the user.
                                                          [self loadHomepage];
                                                      }
                                                      else if ([[account accountType] isEqualToString:clientauth_account_name]) {
                                                          //proceed with authenticating because the app has been authenticated.
                                                          [self setupUser];
                                                      }
                                                  }];
    
    //setup event when authorization fails
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:store
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      NSLog(@"AccountStoreDidFailToRequestAccessNotification: %@", error);
                                                      
                                                      NSString *accountType = [aNotification.userInfo objectForKey:kNXOAuth2AccountStoreAccountType];
                                                      
                                                      if ([accountType isEqualToString:userauth_account_name])
                                                      {
                                                          //logout user because they have lost their access
                                                          [AuthService logout];
                                                      }
                                                      else if ([accountType isEqualToString:clientauth_account_name])
                                                      {
                                                          //app has lost it's authentication for some reason. logout user and display message that app cannot connect to our servers.
                                                          
                                                          
                                                         /*[self displayAlertWithTitle:@"Connection Problem"
                                                                              message:@"We're sorry but there is a connection problem between your device and our servers. Please try again later. Sorry for any inconvenience."
                                                                    cancelButtonTitle:nil
                                                                    otherButtonTitles:@[@"Try Again"]
                                                                      onButtonClicked:^(NSString *buttonTitle) {
                                                                          //[self requestClientAccess];
                                                                      }
                                                           ];
                                                          */
                                                      }
                                                  }];
    
    [self requestClientAccess];
}

//requests app access
- (void)requestClientAccess {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    [store requestClientCredentialsAccessWithType:clientauth_account_name];
};



+(BOOL)isUserAuthenticated
{
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:userauth_account_name];
    return [accounts count] > 0;
}


-(void)setupUser
{
    //check device registration with server
    [DeviceService checkRegistration];
    
    
    if ([AuthService isUserAuthenticated]) {
        NXOAuth2Account *account = [AuthService getUserAccount];
        NXOAuth2Client *client = account.oauthClient;
        
        //if token expires within one day, refresh token
        NSDate *oneDayLater = [NSDate dateWithTimeIntervalSinceNow:(86400)];
        NSDate *tokenExpiresAt = client.accessToken.expiresAt;
        if (client.accessToken.refreshToken && [oneDayLater earlierDate:tokenExpiresAt] == tokenExpiresAt) {
            __block __weak id changeObserver;
            __block __weak id loseObserver;
            changeObserver =[[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidChangeAccessTokenNotification
                                                                              object:account
                                                                               queue:nil
                                                                          usingBlock:^(NSNotification *aNotification){
                                                                              [[NSNotificationCenter defaultCenter] removeObserver:changeObserver];
                                                                              [[NSNotificationCenter defaultCenter] removeObserver:loseObserver];
                                                                              
                                                                              NSLog(@"AccountDidChangeAccessTokenNotification");
                                                                              
                                                                              //load dashboard
                                                                              [self loadHomepage];
                                                                          }];
            
            loseObserver =[[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountDidLoseAccessTokenNotification
                                                                            object:account
                                                                             queue:nil
                                                                        usingBlock:^(NSNotification *aNotification){
                                                                            [[NSNotificationCenter defaultCenter] removeObserver:changeObserver];
                                                                            [[NSNotificationCenter defaultCenter] removeObserver:loseObserver];
                                                                            
                                                                            NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                                            NSLog(@"AccountDidLoseAccessTokenNotification: %@", error);
                                                                            
                                                                            //logout because they lost access
                                                                            [AuthService logout];
                                                                        }];
            
            [client refreshAccessToken];
        } else {
            [self loadHomepage];
        }
    } else {
        [self loadHomepage];
    }
    
    
}

-(void)loadHomepage
{
    BOOL isLoggedIn = [AuthService isUserAuthenticated];
    
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] presentHomepage];
    
    if (isLoggedIn) {
        
        //can check for local or remote notifications to show
        //[self checkLocalNotification];
        //[self checkRemoteNotification];
    }
}

+(NXOAuth2Account*)getClientAccount
{
    
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:clientauth_account_name];
    if (accounts != nil && [accounts count] > 0)
        return accounts[0];
    return nil;
}

+(NXOAuth2Account*)getUserAccount
{
    
    NSArray *accounts = [[NXOAuth2AccountStore sharedStore] accountsWithAccountType:userauth_account_name];
    if (accounts != nil && [accounts count] > 0)
        return accounts[0];
    return nil;
}

+(void)requestUserAccess:(void (^)(NSURL *preparedUrl))authHandler
{
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:userauth_account_name
                                   withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                       authHandler(preparedURL);
                                   }];
}

+ (void)handleAuthUrl:(NSURL *)url {
    if ([[url host] hasSuffix:@"-authcallback"]) {
        [[NXOAuth2AccountStore sharedStore] handleRedirectURL:url];
    }
}

@end
