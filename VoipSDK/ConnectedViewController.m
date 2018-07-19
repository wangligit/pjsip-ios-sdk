//
//  SoftPhoneDialViewController.m
//  VoipSDK
//
//  Created by wanglili on 17/3/21.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import "ConnectedViewController.h"
#import <pjsua-lib/pjsua.h>
#import "ImageAPI.h"
#import "MyCallCollectionViewCell.h"
#import "RGBColorAPI.h"
#import "DWRipplesLayer.h"
#import "Constants.h"
#import "MyPjsipService.h"
@import CoreTelephony;

@interface ConnectedViewController()<FloatingWindowTouchDelegate> {
    pjsua_call_id _call_id;
    NSTimer *myChatTimer;
    int chatTime;
    NSString *callNumber;
}
@property (weak, nonatomic) IBOutlet UILabel *callUser;
@property (weak, nonatomic) IBOutlet UILabel *calltime;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property NSMutableArray *cellViewItems;

@end

@implementation ConnectedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCallStatusChanged:)
                                                 name:@"SIPCallStatusChangedNotification"
                                               object:nil];
    [self setproximity];
    NSLog(@"+++++++++++displayName:%@",self.displayName);
    
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
    
    NSArray *CellImgName = [[NSArray alloc] initWithObjects:@"unmute",@"hangup",@"unspeaker",@"tosmall", nil];
    NSArray *CellTitleName = [[NSArray alloc] initWithObjects:@"静音",@"挂断",@"免提",@"最小化",nil];
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGSize size = rect.size;
    CGFloat width = size.width;
    
    for (int i=0; i < [CellImgName count]; i++) {
        MyCallCollectionViewCell  *appview = [[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
        float dr = 72;
        
        //unmute hangup unspeaker
        if (i==0 || i==1 || i==2) {
            
            appview.frame = CGRectMake(width/3*i, size.height*0.75, width/3, dr+35);
            [self.view addSubview:appview];
            appview.tagImg.frame = CGRectMake(width/6-dr/2, 8, dr, dr);
            appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:i]];
            appview.tagLabel.frame = CGRectMake(width/6-50/2, dr+15, 50, 20);
            appview.tagLabel.text = [CellTitleName objectAtIndex:i];
            appview.layer.borderWidth = 0.0f;
        }
        //tosmall
        if (i == 3) {
            appview.frame = CGRectMake(width/5*4, size.height*0.05, width/5, 50);
            [self.view addSubview:appview];
            appview.tagImg.frame = CGRectMake(8, 8, 36, 26);
            appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:i]];
            appview.tagLabel.text = [CellTitleName objectAtIndex:i];
            appview.tagLabel.hidden = YES;
            appview.layer.borderWidth = 0.0f;
        }
        
        //添加点击事件
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"unmute"]) {
            [appview.tagBtn addTarget:self action:@selector(muteAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"hangup"]) {
            [appview.tagBtn addTarget:self action:@selector(hangupAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"unspeaker"]) {
            [appview.tagBtn addTarget:self action:@selector(speakerAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        if ([[CellImgName objectAtIndex:i] isEqualToString:@"tosmall"]) {
            [appview.tagBtn addTarget:self action:@selector(minimize:) forControlEvents:UIControlEventTouchUpInside];
        }

    }
    /*-----------------最小化------------------*/
    self.floatWindow = [[FloatingWindow alloc] initWithFrame:CGRectMake(100, 100, 76, 76) imageName:@"av_call"];
    /*-----------------------被叫头像----------------------------*/
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[ImageAPI imageWithName:@"pic1"]];
    imgView.frame = CGRectMake(width/2-50, size.height*0.40, 100, 100);
    [self.view addSubview:imgView];
    _callUser.text = self.displayName;
    _calltime.text = @"";
    
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
    
    if (call_id != _call_id) return;
    if (state == PJSIP_INV_STATE_DISCONNECTED) {
        NSLog(@"断开连接....");
        _calltime.text = @"通话结束";
        [self stopTimer];
        [self.floatWindow close];
        [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        self.floatWindow.floatDelegate = nil;
    } else if (state == PJSIP_INV_STATE_CONNECTING) {
        NSLog(@"正在连接...");
        _calltime.text = @"已接通";
        [self stopTimer];
    } else if (state == PJSIP_INV_STATE_CONFIRMED) {
        NSLog(@"连接成功....");
        [self startTimer];

    }
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

- (void)hangupAction:(UIButton *)sender {
    NSLog(@"hangup is clicked!");
    pjsua_call_hangup_all();
    [self stopTimer];
    [self sensorDealloc];
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    
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
}


- (void)sensorDealloc {
    NSLog(@"++++++sensorDealloc NSNotificationCenter remove+++++++++++++");
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
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (void)assistiveTocuhs {
    
    self.floatWindow.isCannotTouch = YES;
    [self setproximity];
}


@end
