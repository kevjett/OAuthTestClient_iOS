//
//  Functions.m
//  Kevin Jett
//
//  Created by Kevin Jett on 3/6/15.
//  Copyright (c) 2015 Kevin Jett. All rights reserved.
//

#import "Functions.h"

@implementation Functions

+(NSUInteger)indexOfCaseInsensitive:(NSArray*)arr str:(NSString*)str {
    NSUInteger index = 0;
    for (NSString *object in arr) {
        if ([object caseInsensitiveCompare:str] == NSOrderedSame) {
            return index;
        }
        index++;
    }
    return NSNotFound;
}

+(NSString*)pluralWord:(NSNumber*)count singular:(NSString*)singular plural:(NSString*)plural
{
    return [count intValue] == 1 ? singular : plural;
}

+(NSNumber*)toNumber:(id)value {
    if ([value isKindOfClass:[NSNumber class]])
    {
        return value;
    }
    
    @try {
        NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        return [f numberFromString:value];
    }
    @catch (NSException *exception) {
        NSLog(@"Parse number error. Value: %@ Exception: %@", value, [exception description]);
        return [NSNumber numberWithInt:0];
    }
}

+(NSDate*)toDate:(id)value {
    @try
    {
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        if ([value length] > 11)
        {
            [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        }
        else
        {
            [dateFormat setDateFormat:@"yyyy-MM-dd"];
        }
        return [dateFormat dateFromString:value];
    }
    @catch(NSException *ex)
    {
        NSLog(@"Add date parse exception. Value: %@ Exception: %@", value, [ex description]);
        return nil;
    }
}

+(BOOL)toBool:(id)value {
    if ([value isKindOfClass:[NSNumber class]])
    {
        return [value isEqual:[NSNumber numberWithInt:1]] ? YES : NO;
    }
    if ([value isKindOfClass:[NSString class]])
    {
        return ([value isEqual: @"1"] || [[value lowercaseString] isEqual: @"true"]) ? YES : NO;
    }
    return [value isEqual: @"1"] ? YES : NO;
}


@end
