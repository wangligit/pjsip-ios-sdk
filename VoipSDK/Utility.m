//
//  Utility.m
//  VoipSDK
//
//  Created by wanglili on 17/3/9.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (BOOL) isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0) {
        return YES;
    }
    return NO;
}

@end
