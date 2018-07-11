//
//  WiFiUtils.m
//  VoipSDK
//
//  Created by wanglili on 17/6/9.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import "WiFiUtils.h"

@implementation WiFiUtils

+ (NSString *)SSID {
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    NSLog(@"%s: Supported interfaces: %@", __func__, interfaceNames);
    
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(
                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty) {
            break;
        }
    }
    NSString *SSID = SSIDInfo[@"SSID"];
    return SSID;
}

@end
