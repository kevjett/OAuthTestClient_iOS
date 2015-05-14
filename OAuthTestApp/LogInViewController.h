//
//  LogInViewController.h
//  OAuthTestApp
//
//  Created by Kevin Jett on 5/13/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogInViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end
