//
//  IncomingCallViewController.m
//  SimpleSipPhone
//
//  Created by MK on 15/5/23.
//  Copyright (c) 2015年 Makee. All rights reserved.
//

#import <pjsua-lib/pjsua.h>
#import "IncomingCallViewController.h"
#import "ConnectedViewController.h"
#import "RGBColorAPI.h"
#import "DWRipplesLayer.h"
#import "MyCallCollectionViewCell.h"
#import "ImageAPI.h"

@interface IncomingCallViewController ()<FloatingWindowTouchDelegate>

@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (nonatomic, strong) DWRipplesLayer *ripplesLayer;
@end

@implementation IncomingCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _phoneNumberLabel.text=self.displayName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleCallStatusChanged:)
                                                 name:@"SIPCallStatusChangedNotification"
                                               object:nil];
    //---------------------------添加背景------------------------
    UIImageView *myUIview=[[UIImageView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:myUIview];
    [self.view sendSubviewToBack:myUIview];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = myUIview.bounds;
    [myUIview.layer addSublayer:gradientLayer];
    UIColor *color1= UIColorFromHex(0x003366);//2895B4
    UIColor *color2= UIColorFromHex(0x005588);//42b4d5
    UIColor *color3= UIColorFromHex(0x0077AA);//64c1dd
    //set gradient colors
    gradientLayer.colors = @[(__bridge id)color1.CGColor, (__bridge id) color2.CGColor, (__bridge id)color3.CGColor,(__bridge id)color3.CGColor,(__bridge id) color2.CGColor,(__bridge id)color1.CGColor];
    //set locations
    gradientLayer.locations = @[@0.0, @0.3, @0.5, @0.65, @0.8, @1.0];
    //set gradient start and end points
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    
     //-----------------------添加挂断按钮------------------------
    NSArray *CellImgName = [[NSArray alloc] initWithObjects:@"hangup",@"answer",@"tosmall", nil];
    NSArray *CellTitleName = [[NSArray alloc] initWithObjects:@"拒绝",@"接听",@"最小化", nil];
    
    MyCallCollectionViewCell  *appview=[[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
    float dr = 72;
    appview.frame=CGRectMake(kScreenWidth/2*0, kScreenHeight*0.75, kScreenWidth/2, dr+30);//100
    [self.view addSubview:appview];
    appview.tagImg.frame = CGRectMake(kScreenWidth/4-dr/2, 8, dr, dr);
    appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:0]];
    appview.tagLabel.frame = CGRectMake(kScreenWidth/4-50/2, dr+10, 50, 20);//width/6-50/2, 68, 50, 20
    appview.tagLabel.text = [CellTitleName objectAtIndex:0];
    appview.tagBtn.frame = CGRectMake(kScreenWidth/4-dr/2, 8, dr, dr+30);
    appview.layer.borderWidth = 0.0f;
     //-----------------------添加接听按钮------------------------
    MyCallCollectionViewCell  *appview2=[[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
    appview2.frame=CGRectMake(kScreenWidth*1/2, kScreenHeight*0.75, kScreenWidth/2, dr+30);//100
    [self.view addSubview:appview2];
    appview2.tagImg.frame = CGRectMake(kScreenWidth/4-dr/2, 8, dr, dr);
    appview2.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:1]];
    appview2.tagLabel.frame = CGRectMake(kScreenWidth/4-50/2, dr+10, 50, 20);//width/6-50/2, 68, 50, 20
    appview2.tagLabel.text = [CellTitleName objectAtIndex:1];
    appview2.tagBtn.frame = CGRectMake(kScreenWidth/4-dr/2, 8, dr, dr+30);
    appview2.layer.borderWidth = 0.0f;
    //-----------------------添加最小化按钮------------------------
    MyCallCollectionViewCell  *appview3=[[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
    appview3.frame = CGRectMake(kScreenWidth/5*4, kScreenHeight*0.05, kScreenWidth/5, 50);
    [self.view addSubview:appview3];
    appview3.tagImg.frame = CGRectMake(8, 8, 36, 26);
    appview3.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:2]];
    appview3.tagLabel.text = [CellTitleName objectAtIndex:2];
    appview3.tagLabel.hidden = YES;
    appview3.layer.borderWidth = 0.0f;
    
    /*-----------------最小化------------------*/
    self.floatWindow = [[FloatingWindow alloc] initWithFrame:CGRectMake(100, 100, 76, 76) imageName:@"av_call"];
    /*-----------------------被叫头像----------------------------*/
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[ImageAPI imageWithName:@"pic1"]];
    imgView.frame = CGRectMake(kScreenWidth/2-50, kScreenHeight*0.40, 100, 100);
    self.ripplesLayer = [[DWRipplesLayer alloc] init];
    [self.view.layer insertSublayer:self.ripplesLayer below:imgView.layer];
    self.ripplesLayer.position = imgView.center;
    [self.ripplesLayer startAnimation];
    [self.view addSubview:imgView];
    
    //-------------------------为点击添加监听事件------------------------
    [appview.tagBtn addTarget:self action:@selector(hangupAction:) forControlEvents:UIControlEventTouchUpInside];
    [appview2.tagBtn addTarget:self action:@selector(answerAction:) forControlEvents:UIControlEventTouchUpInside];
    [appview3.tagBtn addTarget:self action:@selector(minimize:) forControlEvents:UIControlEventTouchUpInside];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleCallStatusChanged:(NSNotification *)notification {
    NSLog(@"----------------self.callId:%li-----------------",(long)self.callId);
    pjsua_call_id call_id = [notification.userInfo[@"call_id"] intValue];
    pjsip_inv_state state = [notification.userInfo[@"state"] intValue];
    NSLog(@"-------callStatusChanged->state:%d,call_id:%d,self.callId:%ld",state,call_id,(long)self.callId);
    if(call_id != self.callId) return;
    
    if (state == PJSIP_INV_STATE_DISCONNECTED) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else if(state == PJSIP_INV_STATE_CONNECTING){
        NSLog(@"连接中...");
    } else if(state == PJSIP_INV_STATE_CONFIRMED) {
        NSLog(@"接听成功！");
    }
}


-(void)hangupAction:(UIButton *)sender {
    pjsua_call_hangup((pjsua_call_id)self.callId, 0, NULL, NULL);
    [self.ripplesLayer stopAnimation];
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)answerAction:(UIButton *)sender {
    pjsua_call_answer((pjsua_call_id)self.callId, 200, NULL, NULL);
    [self.ripplesLayer stopAnimation];
    UIStoryboard *storyBoard =  [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle bundleForClass:[self class]]];
    ConnectedViewController *viewController = [storyBoard instantiateViewControllerWithIdentifier:@"ConnectedViewController"];
    
    viewController.displayName = self.displayName;
    viewController.calleeNumber = self.phoneNumber;
    [self presentViewController:viewController animated:YES completion:nil];
 
}

/*
 *功能：窗口最小化
 *
 */
- (void)minimize:(UIButton *)sender {
    self.floatWindow.isCannotTouch = NO;
    self.floatWindow.floatDelegate = self;
    [self.floatWindow startWithTime:self.view inRect:  CGRectMake([UIScreen mainScreen].bounds.size.width - 100, [UIScreen mainScreen].bounds.size.height - 200, 76, 76)];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)assistiveTocuhs {
    
    self.floatWindow.isCannotTouch = YES;
}

@end
