//
//  MyPjsipService.m
//  VoipSDK
//
//  Created by wanglili on 17/3/20.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import "MyPjsipService.h"
#import <pjsua-lib/pjsua.h>
#import "SoftPhoneDialViewController.h"
#import "IncomingCallViewController.h"
#import "PjsipManager.h"
#import "GTMBase64.h"
#import "NSData+AES.h"
#import "RealReachability/RealReachability.h"
#import "Utility.h"

@interface MyPjsipService(){
    
    NSString *sipUser;
    NSString *pwd;
    NSString *ip;
    NSString *calleeNumber;
    NSString *calleeName;
    NSDictionary *sipHeader;
    UIViewController *uvController;
}
@property (nonatomic,strong)PjsipManager *pjsipManager;

@end
@implementation MyPjsipService

+ (instancetype)sharedPjsipService {
    static MyPjsipService *pjsipService;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pjsipService = [[self alloc] init];
        pjsipService.pjsipManager = [PjsipManager sharedPjsipManager];
    });
    return pjsipService;
}

- (void)switchToDialViewController:(UIViewController *) vc calleeNumber:(NSString *) callNumber  calleeName:(NSString *) userName {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIStoryboard *storyBoard =  [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle bundleForClass:[self class]]];
        SoftPhoneDialViewController *dialViewController = [storyBoard instantiateViewControllerWithIdentifier:@"SoftPhoneDialViewController"];
        if (![dialViewController isEqual: vc]) {
            dialViewController.displayName = userName;
            dialViewController.calleeNumber = callNumber;
            dialViewController.originFlag = 1;
            UINavigationController *navigationcontoller = [[UINavigationController alloc]initWithRootViewController:dialViewController];
            navigationcontoller.navigationBar.hidden = YES;
            [vc presentViewController:navigationcontoller animated:YES completion:^{
            }];
        }
        
    });
}


- (int)pjsipInitForSoftphone:(NSString *)user password:(NSString *) password serverAdd:(NSString *)server{
    //NSString *proxy = SIP_PROXY;
    //NSData *data = [password dataUsingEncoding:NSUTF8StringEncoding];
    //data = [GTMBase64 decodeData:data];
    //NSData *decData = [data AES128DecryptWithKey:AES_KEY iv:AES_IV];
    //NSString *pwd = [[NSString alloc] initWithData:decData encoding:NSUTF8StringEncoding];
    //NSLog(@"++++++sip:%@",pwd);
    //[_pjsipManager pjsipInit:user password:pwd server:SIP_SERVER proxy:[NSString stringWithFormat:@"%@",proxy]];
    //        [_pjsipManager pjsipInit:user password:password server:SIP_SERVER proxy:@"" customMessage:NULL];
    return [_pjsipManager pjsipInit:user password:password server:server proxy:NULL];
    
}



- (void)checkMicPhoneStatus:(UIViewController *) vc{
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
        //第一次询问用户是否进行授权
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            // CALL YOUR METHOD HERE - as this assumes being called only once from user interacting with permission alert!
            if (granted) {
                // Microphone enabled code
            }
            else {
                // Microphone disabled code
            }
        }];
    }else if(videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) {// 未授权
        [self showSetAlertView:vc];
    }else{// 已授权
        
    }
}

//提示用户进行麦克风使用授权
- (void)showSetAlertView:(UIViewController *) vc{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"麦克风权限未开启" message:@"麦克风权限未开启，请进入系统【设置】>【隐私】>【麦克风】中打开开关,开启麦克风功能" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //跳入当前App设置界面
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    //[alertVC addAction:cancelAction];
    [alertVC addAction:setAction];
    
    [vc presentViewController:alertVC animated:YES completion:nil];
}

- (int)makeCall:(NSString *)user password:(NSString *)password serverAddr:(NSString *)server callNumber:(NSString *)callNumber displayName:(NSString *)displayName customMessage:(NSDictionary *)message vController:(UIViewController *)vc{
    if([Utility isBlankString:user]){
        return 100;
    }
    if([Utility isBlankString:password]){
        return 101;
    }
    if([Utility isBlankString:server]){
        return 102;
    }
    if([Utility isBlankString:callNumber]){
        return 103;
    }
    if([Utility isBlankString:displayName]){
        calleeName = callNumber;
    }else{
        calleeName = displayName;
    }
    if(vc == nil){
        return 104;
    }
    sipUser = user;
    pwd = password;
    ip = server;
    calleeNumber = callNumber;
    sipHeader = message;
    uvController = vc;
    return [self checkForNetwork];
    //return 0;
}

- (int) makeVoipCall{
    [self switchToDialViewController:uvController calleeNumber:calleeNumber calleeName:calleeName];
    NSLog(@"registerUser:%@", sipUser);
    [self pjsipInitForSoftphone:sipUser password:pwd serverAdd:ip];
    NSLog(@"<<<<<<voip callNumber:%@",calleeNumber);
    return [_pjsipManager makeCall:calleeNumber server:ip customHeader:sipHeader];
}

- (int)checkForNetwork
{
    [GLobalRealReachability startNotifier];
    GLobalRealReachability.hostForPing = ip;
    GLobalRealReachability.pingTimeout = 0.3f;
    // WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
    [GLobalRealReachability reachabilityWithBlock:^(ReachabilityStatus status) {
        [GLobalRealReachability stopNotifier];
        //网络监测记录
        switch (status)
        {
            case RealStatusNotReachable:
            {
                NSLog(@"NotReachable handler");
                //                self.NetworkStaus = @"NoNetwork";
                [self showTipAlertView:@"当前网络质量不好，请稍候重试"];
                return;
            }
            case RealStatusViaWiFi:
            {
                // 在网络畅通并且是wifi情况下直接拨打电话
                NSLog(@"WiFi handler");
                //                self.NetworkStaus = @"WiFi";
                //[self makeVoipCall];
                return;
            }
            case RealStatusViaWWAN:
            {
                /*
                 if (accessType == WWANType4G)
                 {
                 self.NetworkStaus = @"4G";
                 }
                 else
                 {
                 self.NetworkStaus = @"非4G";
                 }*/
                //[self makeVoipCall];
                return;
                
            }
                
            default:
                NSLog(@"no handler");
                //self.NetworkStaus = @"默认";
                return;
        }
    }];
    
    return [self makeVoipCall];
    
}

//提示用户网络质量
- (void)showTipAlertView:(NSString *) message{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"网络质量检测" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *setAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    //    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    //
    //    }];
    //[alertVC addAction:cancelAction];
    [alertVC addAction:setAction];
    
    [uvController presentViewController:alertVC animated:YES completion:nil];
}

/*********************接听***************************/

- (void)switchToIncomingViewController:(UIViewController *) vc calleeNumber:(NSString *) callNumber  calleeName:(NSString *) userName callId:(NSInteger) callid {
    NSLog(@"----fromeCallNumber:%@,fromCallId:%li",callNumber,(long)callid);
    UIStoryboard *storyBoard =  [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle bundleForClass:[self class]]];
    IncomingCallViewController *incomingViewController = [storyBoard instantiateViewControllerWithIdentifier:@"incomingCallViewController"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![incomingViewController isEqual: vc]) {
            incomingViewController.displayName = userName;
            incomingViewController.phoneNumber = callNumber;
            incomingViewController.callId = callid;
            incomingViewController.flag=1;
            [vc presentViewController:incomingViewController animated:YES completion:^{
            }];
        }
    });
}

@end
