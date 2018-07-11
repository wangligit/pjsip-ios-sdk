//
//  PjsipManager.h
//  VoipSDK
//
//  Created by wanglili on 17/3/13.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PjsipManager : NSObject

+ (instancetype)sharedPjsipManager;

- (int)pjsipInit:(NSString *) user password:(NSString *) pwd server:(NSString *) addr proxy:(NSString *) proxy;

- (int)makeCall:(NSString *)callNumber server:(NSString *) addr customHeader:(NSDictionary *) headers;

- (void)hangup;

- (void)answerCall;

- (void)systemMakeCall:(NSString *) callNumber;

/*
 *功能:设置话筒
 *参数:
 *      ABool   YES非静音  NO静音
 */
- (void)Microphone:(BOOL)ABool;

/*
 *功能:扬声器与听筒的切换
 *参数:
 *      isSpeaker   YES扬声器  NO听筒
 */
- (void)setISSpeaker:(BOOL)isSpeaker;

- (void)sendDTMFDigits:(NSString *)digitsStr;

@end
