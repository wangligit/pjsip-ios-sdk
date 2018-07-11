//
//  MyPjsipService.h
//  VoipSDK
//
//  Created by wanglili on 17/3/20.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MyPjsipService : NSObject

+ (instancetype)sharedPjsipService;

- (void)switchToDialViewController:(UIViewController *) vc calleeNumber:(NSString *) callNumber calleeName:(NSString *) userName;

- (int)pjsipInitForSoftphone:(NSString *)user password:(NSString *) password serverAdd:(NSString *)server;

- (int)makeCall:(NSString *)user password:(NSString *)password serverAddr:(NSString *)server callNumber:(NSString *)callNumber displayName:(NSString *)displayName customMessage:(NSDictionary *)message vController:(UIViewController *)vc;

- (void)switchToIncomingViewController:(UIViewController *) vc calleeNumber:(NSString *) callNumber calleeName:(NSString *) userName callId:(NSInteger) callid;

@end
