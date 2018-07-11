//
//  MobileAPI.h
//  VoipSDK
//
//  Created by wanglili on 16/12/28.
//  Copyright © 2016年 wanglili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import<CoreTelephony/CTTelephonyNetworkInfo.h>
#import<CoreTelephony/CTCarrier.h>

@interface MobileAPI : NSObject

+ (NSString*)checkCarrier;

@end
