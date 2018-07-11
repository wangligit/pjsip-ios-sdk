//
//  MobileAPI.m
//  VoipSDK
//
//  Created by wanglili on 16/12/28.
//  Copyright © 2016年 wanglili. All rights reserved.
//
#import "MobileAPI.h"
#import "Utility.h"

static NSString * const CHINAUNICOM = @"";
static NSString * const CHINAMOBILE = @"";
static NSString * const CHINANET = @"";

@implementation MobileAPI

+ (NSString*)checkCarrier{
    
    NSString *ret = CHINAUNICOM;
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [info subscriberCellularProvider];
    if ( carrier == nil )
    {
        return(ret);
    }
    NSString *code = [carrier mobileNetworkCode];
    NSLog(@"----------------mobileNetworkCode:%@----------------", code);
    if ([Utility isBlankString:code])
    {
        return(ret);
    }

    if ( [code isEqualToString:@"00"] || [code isEqualToString:@"02"] || [code isEqualToString:@"07"] )
    {
        ret = CHINAMOBILE;
    }
    
    if ( [code isEqualToString:@"01"] || [code isEqualToString:@"06"] )
    {
        ret = CHINAUNICOM;
    }
    
    if ( [code isEqualToString:@"03"] || [code isEqualToString:@"05"] )
    {
        ret = CHINANET;
    }

    return(ret);

}

@end
