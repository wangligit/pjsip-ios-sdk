//
//  SoftPhoneDialViewController.h
//  VoipSDK
//
//  Created by wanglili on 17/3/21.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FloatingWindow.h"

@interface SoftPhoneDialViewController : UIViewController

@property(strong,nonatomic)NSString *displayName;

@property(strong,nonatomic)NSString *calleeNumber;

@property(strong, nonatomic)FloatingWindow *floatWindow;

@property(nonatomic) int originFlag;

@end
