//
//  Constants.h
//  VoipSDK
//
//  Created by wanglili on 16/11/17.
//  Copyright © 2016年 wanglili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject


extern NSString * const SIP_SERVER;
extern NSString * const SIP_PROXY;
extern NSString * const PREFIX_NAME;
extern NSString * const AES_KEY;
extern NSString * const AES_IV;

typedef NS_ENUM(NSUInteger, TypeEnum){
    INNER_EXT = 0,
    INNER_PHONE,
    EXTERNAL_NUMBER
};

@end
