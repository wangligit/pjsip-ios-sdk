//
//  SoftPhoneDialViewController.m
//  VoipSDK
//
//  Created by wanglili on 17/3/21.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import "SoftPhoneDialViewController.h"
#import <pjsua-lib/pjsua.h>
#import "ImageAPI.h"
#import "MyCallCollectionViewCell.h"
#import "RGBColorAPI.h"
#import "DWRipplesLayer.h"
#import "Constants.h"
#import "MyPjsipService.h"
@import CoreTelephony;

@interface SoftPhoneDialViewController()<FloatingWindowTouchDelegate> {
    pjsua_call_id _call_id;
    NSTimer *myChatTimer;
    int chatTime;
    int flag;
    NSString *callNumber;
}
@property (weak, nonatomic) IBOutlet UILabel *callUser;
@property (weak, nonatomic) IBOutlet UILabel *calltime;
@property (strong, nonatomic) IBOutlet UILabel *prompt;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property NSMutableArray *cellViewItems;
@property (nonatomic, strong) DWRipplesLayer *ripplesLayer;
@property (strong, nonatomic) IBOutlet UILabel *callDialpadNumber;
@property (strong, nonatomic) CTCallCenter *callCenter;

@end

@implementation SoftPhoneDialViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addCallCenterBlock];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCallStatusChanged:)
                                                 name:@"SIPCallStatusChangedNotification"
                                               object:nil];
    [self startAnimationTimer];
    [self setproximity];
    NSLog(@"+++++++++++displayName:%@",self.displayName);
    flag = 0;
    
    /*--------------------背景渐变-------------------*/
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = self.containerView.bounds;
    [self.containerView.layer addSublayer:gradientLayer];
    UIColor *color1 = UIColorFromHex(0x003366);//2895B4
    UIColor *color2 = UIColorFromHex(0x005588);//42b4d5
    UIColor *color3 = UIColorFromHex(0x0077AA);//64c1dd
    //set gradient colors
    gradientLayer.colors = @[(__bridge id)color1.CGColor, (__bridge id) color2.CGColor, (__bridge id)color3.CGColor,(__bridge id)color3.CGColor,(__bridge id) color2.CGColor,(__bridge id)color1.CGColor];
    //set locations
    gradientLayer.locations = @[@0.0, @0.3, @0.5, @0.65, @0.8, @1.0];
    
    //set gradient start and end points
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    
    /*--------------------初始化按钮--------------------*/
    self.cellViewItems = [[NSMutableArray alloc] init];
    
    NSArray *CellImgName = [[NSArray alloc] initWithObjects:@"unmute",@"keyboard",@"unspeaker",@"hangup",@"tosmall", @"hidedialpad",nil];
    NSArray *CellTitleName = [[NSArray alloc] initWithObjects:@"静音",@"键盘",@"免提",@"取消",@"最小化", @"隐藏",nil];
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGSize size = rect.size;
    CGFloat width = size.width;
    
    for (int i=0; i < [CellImgName count]; i++) {
        MyCallCollectionViewCell  *appview = [[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
        float dr = 72;
        
        //unmute keyboard unspeaker
        if (i==0 || i==1 || i==2) {
            
            appview.frame = CGRectMake(width/3*i, size.height*0.62, width/3, dr+35);
            [self.view addSubview:appview];
            appview.tagImg.frame = CGRectMake(width/6-dr/2, 8, dr, dr);
            appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:i]];
            appview.tagLabel.frame = CGRectMake(width/6-50/2, dr+15, 50, 20);
            appview.tagLabel.text = [CellTitleName objectAtIndex:i];
            appview.layer.borderWidth = 0.0f;
        }
        //hangup
        if (i == 3) {
            appview.frame=CGRectMake(width/3, size.height*0.79, width/3, dr+35);
            [self.cellViewItems addObject:appview];
            //add by ying
            [appview setTag:13];
            [self.view addSubview:appview];
            appview.tagImg.frame = CGRectMake(width/6-dr/2, 8, dr, dr);
            appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:i]];
            appview.tagLabel.frame = CGRectMake(width/6-50/2, dr+15, 50, 20);
            appview.tagLabel.text = [CellTitleName objectAtIndex:i];
            appview.layer.borderWidth = 0.0f;
        }
        //tosmall
        if (i == 4) {
            appview.frame = CGRectMake(width/5*4, size.height*0.05, width/5, 50);
            [self.view addSubview:appview];
            appview.tagImg.frame = CGRectMake(8, 8, 36, 26);
            appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:i]];
            appview.tagLabel.text = [CellTitleName objectAtIndex:i];
            //add by ying
            appview.tagLabel.hidden = YES;
            appview.layer.borderWidth = 0.0f;
        }
        //hidedialpad
        if (i == 5) {
            UIButton *hideDialpadTextBtn = [[UIButton alloc]initWithFrame:CGRectMake(width/3*2, size.height*0.85, width/3, 50)];
            [hideDialpadTextBtn setTitle:@"隐藏" forState:UIControlStateNormal];
            [hideDialpadTextBtn setTag:16];
            [hideDialpadTextBtn setHidden:YES];
            [hideDialpadTextBtn addTarget:self action:@selector(hideDialpadAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.view addSubview:hideDialpadTextBtn];
            
        }
        //添加点击事件
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"unmute"]) {
            [appview setTag:10];
            [appview.tagBtn addTarget:self action:@selector(muteAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"hangup"]) {
            [appview.tagBtn addTarget:self action:@selector(hangupAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"unspeaker"]) {
            [appview setTag:12];
            [appview.tagBtn addTarget:self action:@selector(speakerAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"tosmall"]) {
            [appview.tagBtn addTarget:self action:@selector(minimize:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"keyboard"]) {
            [appview setTag:11];
            [appview.tagBtn addTarget:self action:@selector(keyboardAction:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    /*-----------------最小化------------------*/
    self.floatWindow = [[FloatingWindow alloc] initWithFrame:CGRectMake(100, 100, 76, 76) imageName:@"av_call"];
    /*-----------------------被叫头像----------------------------*/
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[ImageAPI imageWithName:@"pic1"]];
    imgView.frame = CGRectMake(width/2-50, size.height*0.40, 100, 100);
    self.ripplesLayer = [[DWRipplesLayer alloc] init];
    [self.view.layer insertSublayer:self.ripplesLayer below:imgView.layer];
    self.ripplesLayer.position = imgView.center;
    [self.ripplesLayer startAnimation];
    //add by ying
    [imgView setTag:15];
    [self.view addSubview:imgView];
    _callUser.text = self.displayName;
    _calltime.text = @"正在呼叫";
    _prompt.text = @"";
    self.callDialpadNumber.hidden = YES;
    [self showDialpad];
    
}

- (void)dealloc {
    NSLog(@"--------------------------dealloc------------------------");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.floatWindow.floatDelegate = nil;
    [self sensorDealloc];
    [self stopTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleCallStatusChanged:(NSNotification *)notification {
    pjsua_call_id call_id = [notification.userInfo[@"call_id"] intValue];
    pjsip_inv_state state = [notification.userInfo[@"state"] intValue];
    _call_id = call_id;
    NSLog(@"===========handleCallStatusChanged========call_id:%d,state:%d,_call_id:%d",call_id,state,_call_id);
    _prompt.text = @"";
    
    if (call_id != _call_id) return;
    if (state == PJSIP_INV_STATE_DISCONNECTED) {
        NSLog(@"断开连接....");
        _calltime.text = @"通话结束";
        [self stopTimer];
        [self.floatWindow close];
        if (self.originFlag == 2) {
            self.presentingViewController.view.alpha = 0;
            [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
        }
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        self.floatWindow.floatDelegate = nil;
    } else if (state == PJSIP_INV_STATE_CONNECTING) {
        NSLog(@"正在连接...");
        flag = 1;
        _calltime.text = @"已接通";
        [self stopTimer];
    } else if (state == PJSIP_INV_STATE_CONFIRMED) {
        NSLog(@"连接成功....");
        flag = 2;
        for (int i=0; i<self.cellViewItems.count; ) {
            MyCallCollectionViewCell *viewCell = (MyCallCollectionViewCell *)[self.cellViewItems objectAtIndex:i];
            if ([viewCell.tagLabel.text isEqualToString:@"取消"]) {
                viewCell.tagLabel.text = @"";
                [viewCell setTag:13];
            }
            [self.cellViewItems removeObjectAtIndex:i];
        }
        [self startTimer];
        [self.ripplesLayer stopAnimation];
    }
}

- (void)showDialpad {
    
    float diameter = 72;
    float outMarginx = (kScreenWidth - diameter * 3) * 0.625 / 2;
    float inMarginx = (kScreenWidth - diameter * 3) * 0.375 / 2;
    
    float inMarginy = (kScreenHeight - diameter * 5) * 0.053;
    float outMarginTop = (kScreenHeight - diameter * 5) * 0.495;
    
    UIView *btnTotalView = [[UIView alloc]initWithFrame:CGRectMake(0,  outMarginTop+inMarginy, kScreenWidth, (diameter + inMarginy) * 4)];
    
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j<3; j++) {
            float xoffset = outMarginx + diameter * j + inMarginx * j;
            float yoffset = diameter * i + inMarginy * i;
            
            NSString *btnTitle = [[NSString alloc]init];
            if (i < 3) {
                btnTitle = [NSString stringWithFormat:@"%d",3*i + (j+1)];
            } else {
                if (j == 0) {//*
                    btnTitle = @" ";//1 space
                } else if (j == 1) {//0
                    btnTitle = @"0";
                } else {//#
                    btnTitle = @"#";
                }
            }
            
            UIButton *btntest = [[UIButton alloc] initWithFrame:CGRectMake(xoffset, yoffset, diameter+2, diameter+2)];
            [btntest setTitle:btnTitle forState:UIControlStateNormal];
            if ([btntest.titleLabel.text isEqualToString:@" "]) {//*  a space
                [btntest setBackgroundImage:[ImageAPI imageWithName:@"asterisk"] forState:UIControlStateNormal];
            } else {
                btntest.titleLabel.font = [UIFont systemFontOfSize:32.0];
            }
            [btntest setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [btntest setBounds:CGRectMake(0, 0, diameter, diameter)];
            [btntest.layer setBorderWidth:1.0];
            [btntest.layer setBorderColor:[UIColor whiteColor].CGColor];
            btntest.layer.masksToBounds = YES;
            btntest.layer.cornerRadius = btntest.frame.size.height/2;
            
            [btntest addTarget:self action:@selector(keyTouchDownAction:) forControlEvents:UIControlEventTouchDown];
            [btntest addTarget:self action:@selector(inputNumAction:) forControlEvents:UIControlEventTouchUpInside];
            
            [btnTotalView addSubview:btntest];
        }
    }//for j
    
    [btnTotalView setTag:666];
    [btnTotalView setHidden:YES];
    [btnTotalView setUserInteractionEnabled:YES];
    [self.view addSubview:btnTotalView];
    
    
}

- (void)keyTouchDownAction:(UIButton *)sender {
    //NSLog(@"^^^^^^^^keyTouchdown^^^^^^^^%@",sender.currentTitle);
    UIColor *btnBgColorTouched = UIColorFromHex(0x003366);
    [sender setBackgroundColor:btnBgColorTouched];
    [sender.layer setBorderColor:btnBgColorTouched.CGColor];
    
}


- (void)inputNumAction:(UIButton *)sender {
    // NSLog(@"-------------inputNumAction----------------");
    [sender setBackgroundColor:[UIColor clearColor]];
    [sender.layer setBorderColor:[UIColor whiteColor].CGColor];
    
    self.calltime.hidden = YES;
    self.callUser.hidden = YES;
    self.prompt.hidden = YES;
    self.callDialpadNumber.hidden = NO;
    NSString *inputNumStr = [[NSString alloc]init];
    
    if ([sender.currentTitle isEqualToString:@" "]) {//a space represent a *
        inputNumStr = @"*";
    } else {
        inputNumStr = sender.currentTitle;
    }
    _callDialpadNumber.text = [_callDialpadNumber.text stringByAppendingString:inputNumStr];
    
    [self sendDTMFDigits:inputNumStr];
    
}

- (void)hideDialpadAction:(UIButton *)sender {

    [self.view viewWithTag:666].hidden = YES;
    //image btn
    [self.view viewWithTag:15].hidden = NO;
    //mute btn
    [self.view viewWithTag:10].hidden = NO;
    //keyboard btn
    [self.view viewWithTag:11].hidden = NO;
    //speaker btn
    [self.view viewWithTag:12].hidden = NO;
    //隐藏 btn
    [self.view viewWithTag:16].hidden = YES;
    
    self.calltime.hidden = NO;
    self.callUser.hidden = NO;
    self.prompt.hidden = NO;
    self.callDialpadNumber.hidden = YES;

    if (flag == 0)
        [self.ripplesLayer startAnimation];
    
}

- (void)keyboardAction:(UIButton *)sender {
    [self.view viewWithTag:15].hidden = YES;
    [self.view viewWithTag:10].hidden = YES;
    [self.view viewWithTag:11].hidden = YES;
    [self.view viewWithTag:12].hidden = YES;
    [self.view viewWithTag:16].hidden = NO;
    
    [self.view  viewWithTag:666].hidden = NO;
    
    //show user/time--hide promt/calldialpadNumber
    self.callUser.hidden = NO;
    self.calltime.hidden = NO;
    self.prompt.hidden = YES;
    self.callDialpadNumber.hidden = YES;
    [self.ripplesLayer stopAnimation];
    
}


- (void)muteAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    NSLog(@"-----------sender isClicked: %@------------" ,sender.selected?@"YES":@"NO");
    UIView *v = [sender superview];//获取父类view
    MyCallCollectionViewCell *cell = (MyCallCollectionViewCell *)[v superview];//获取cell
    if (sender.isSelected)
        cell.tagImg.image = [ImageAPI imageWithName:@"mute"];
    else
        cell.tagImg.image = [ImageAPI imageWithName:@"unmute"];
    [self Microphone:!sender.selected];
    
}


//send dtmf digits

- (void)sendDTMFDigits:(NSString *)digitsStr {
    pjsua_call_info ci;
    pjsua_call_get_info(_call_id, &ci);
    
    const pj_str_t pjDigits = pj_str((char *)digitsStr.UTF8String);
    pj_status_t dtmfStatus = pjsua_call_dial_dtmf(_call_id, &pjDigits);
    
    if (dtmfStatus != PJ_SUCCESS) {
        NSLog(@"error ,send dtmf digits");
    } else {
        NSLog(@"dtmf digits sending");
    }
}

/*
 *功能:设置话筒
 *参数:
 *      ABool   YES非静音  NO静音
 */
- (void)Microphone:(BOOL)ABool
{
    if (ABool) {
        pjsua_conf_adjust_rx_level(0, 1);
    } else {
        pjsua_conf_adjust_rx_level(0, 0);
    }
}

/*
 *功能:暂停播放
 *参数:
 *      ABool   YES播放  NO暂停
 */
- (void)PausePlay:(BOOL)ABool {
    pjcall_thread_register2();//首先注册当前线程
    pjsua_call_info ci;
    pjsua_call_get_info(_call_id, &ci);
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        if (ABool) {//播放
            pjsua_conf_connect(ci.conf_slot, 0);
            pjsua_conf_connect(0, ci.conf_slot);
            // enable mic again
            pjsua_conf_adjust_rx_level(ci.conf_slot, 1.0f);
        } else {//暂停
            pjsua_conf_disconnect(ci.conf_slot,0);
            pjsua_conf_disconnect(0,ci.conf_slot);
            pjsua_conf_adjust_rx_level(ci.conf_slot, 0.0f);
        }
    }
}


//线程注册
pj_status_t pjcall_thread_register2(void) {
    pj_thread_desc  desc;
    pj_thread_t* thread = 0;
    
    if (!pj_thread_is_registered()) {
        return pj_thread_register(NULL, desc, &thread);
    }
    
    return PJ_SUCCESS;
}

- (void)hangupAction:(UIButton *)sender {
    NSLog(@"hangup is clicked!");
    pjsua_call_hangup_all();
    [self stopTimer];
    [self sensorDealloc];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
    
}


- (void)speakerAction:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    NSLog(@"-----------sender isClicked: %@------------" ,sender.selected?@"YES":@"NO");
    UIView *v = [sender superview];//获取父类view
    MyCallCollectionViewCell *cell = (MyCallCollectionViewCell *)[v superview];//获取cell
    if (sender.isSelected)
        cell.tagImg.image = [ImageAPI imageWithName:@"speaker"];
    else
        cell.tagImg.image = [ImageAPI imageWithName:@"unspeaker"];

    [self setISSpeaker:sender.selected];//ios7+
}

/*
 *功能:扬声器与听筒的切换
 *参数:
 *      isSpeaker   YES扬声器  NO听筒
 */
- (void)setISSpeaker:(BOOL)isSpeaker {
    if (!isSpeaker) {
        NSLog(@"切换到听筒");
        [self setproximity];
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    } else {//speaker
        NSLog(@"切换到扬声器");
        [self sensorDealloc];
        [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
        
    }
}

//定义timer属性
- (void)startAnimationTimer {
    chatTime = 0;
    myChatTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(reloop:) userInfo:nil repeats:YES];
    
}

- (void)reloop:(NSTimer *)sender {
    chatTime++;
    NSString *dec = chatTime%3==1?@".  ":chatTime%3==2?@".. ":@"...";
    _calltime.text = [NSString stringWithFormat:@"正在呼叫%@",dec];
    if (chatTime == 20)
        _prompt.text = @"对方暂时无法接听，建议稍后重试";
}

//定义timer属性
- (void)startTimer {
    chatTime = 0;
    myChatTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timerFiredMethod:) userInfo:nil repeats:YES];
    
}

//定时器启动后的执行函数
- (void)timerFiredMethod:(NSTimer *)sender {
    chatTime++;
    int hours, minutes, seconds;
    hours = chatTime / 3600;
    minutes = (chatTime % 3600) / 60;
    seconds = (chatTime %3600) % 60;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChattimeNotification" object:self userInfo:@{@"time":@(chatTime)}];
    _calltime.text = [NSString stringWithFormat:@"通话中 %02d:%02d:%02d", hours, minutes, seconds];
    if (chatTime<=8 && ([self.calleeNumber hasPrefix:@"9"] && self.calleeNumber.length==6))
        _prompt.text = @"已接入平台，正在为您呼叫对方，请稍候";
    else
        _prompt.text = @"";
}

//停止定时器
- (void)stopTimer {
    [myChatTimer invalidate];
    myChatTimer = nil;
    chatTime = 0;
    _calltime.text = @"";
}

#pragma mark --设置距离传感器
- (void)setproximity {
    //添加近距离事件监听，添加前先设置为YES，如果设置完后还是NO的读话，说明当前设备没有近距离传感器
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    if ([UIDevice currentDevice].proximityMonitoringEnabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
}
//proximityState 属性 如果用户接近手机，此时属性值为YES，并且屏幕关闭（非休眠）。
- (void)sensorStateChange:(NSNotificationCenter *)notification {
    if ([[UIDevice currentDevice] proximityState]) {
        NSLog(@"Device is close to user");
        //设置AVAudioSession 的播放模式
        //[[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    } else {
        NSLog(@"Device is not close to user");
        //[[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
}

- (void)sensorDealloc {
    NSLog(@"++++++sensorDealloc NSNotificationCenter remove+++++++++++++");
    if ([UIDevice currentDevice].proximityMonitoringEnabled) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    }
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}

#pragma mark--初始化方法
/****************禁止横排**********************/
- (BOOL)shouldAutorotate {
    
    return NO;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}
/****************End**********************/

/*
 *功能：窗口最小化
 *
 */
- (void)minimize:(UIButton *)sender {
    self.floatWindow.isCannotTouch = NO;
    self.floatWindow.floatDelegate = self;
    [self.floatWindow startWithTime:self.view inRect:  CGRectMake([UIScreen mainScreen].bounds.size.width - 100, [UIScreen mainScreen].bounds.size.height - 200, 76, 76)];
    [self sensorDealloc];
    [self.navigationController dismissViewControllerAnimated:NO completion:^{
        
    }];
}

#pragma mark--初始化方法
//初始化来电监听
- (void)addCallCenterBlock {
    self.callCenter = [[CTCallCenter alloc] init];
    __weak SoftPhoneDialViewController* refself = self;
    self.callCenter.callEventHandler = ^(CTCall *call) {
        if ([call.callState isEqualToString:CTCallStateDisconnected]) {
            NSLog(@"Call has been disconnected....");
            //电话挂断-恢复
            [refself enableSoundDevice];
            
        } else if ([call.callState isEqualToString:CTCallStateConnected]) {
            NSLog(@"Call has just been connected....");
        } else if ([call.callState isEqualToString:CTCallStateIncoming]) {
            NSLog(@"Call is incoming....");
            //来电-暂停
            [refself disableSoundDevice];
        } else if ([call.callState isEqualToString:CTCallStateDialing]) {
            NSLog(@"call is dialing....");
        } else {
            NSLog(@"Nothing is done....");
        }
    };
}

/*
 *功能:打开声音设备
 *
 */
- (void)enableSoundDevice {
    pjcall_thread_register2();
    pj_status_t status;
    status = pjsua_set_snd_dev(PJMEDIA_AUD_DEFAULT_CAPTURE_DEV,
                               PJMEDIA_AUD_DEFAULT_PLAYBACK_DEV);
    if (status != PJ_SUCCESS)
        NSLog(@"Failure in enabling sound device");
}

/*
 *功能:关闭声音设备
 *
 */
- (void)disableSoundDevice {
    pjcall_thread_register2();
    pj_status_t status = pjsua_set_null_snd_dev();
    if (status != PJ_SUCCESS)
        NSLog(@"Failure in disabling sound device");
}

- (void)assistiveTocuhs {
    
    self.floatWindow.isCannotTouch = YES;
    [self setproximity];
}


@end
