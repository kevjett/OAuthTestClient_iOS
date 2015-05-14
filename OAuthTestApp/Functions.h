//
//  Functions.h
//  Kevin Jett
//
//  Created by Kevin Jett on 3/6/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Functions : NSObject

+(NSUInteger)indexOfCaseInsensitive:(NSArray*)arr str:(NSString*)str;
+(NSString*)pluralWord:(NSNumber*)count singular:(NSString*)singular plural:(NSString*)plural;
+(NSNumber*)toNumber:(id)value;
+(NSDate*)toDate:(id)value;
+(BOOL)toBool:(id)value;


@end
