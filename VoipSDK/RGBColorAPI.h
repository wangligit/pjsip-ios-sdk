//
//  RGBColorAPI.h
//  VoipSDK
//
//  Created by wanglili on 16/12/22.
//  Copyright © 2016年 wanglili. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RGBColorAPI : NSObject
#define UIColorFromHex(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16))/255.0 green:(((s &0xFF00) >>8))/255.0 blue:((s &0xFF))/255.0 alpha:1.0]

#define WIDTH self.frame.size.width

#define HEIGHT self.frame.size.height

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width

#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

@end
