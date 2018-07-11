//
//  IncomingCallViewController.m
//  SimpleSipPhone
//
//  Created by MK on 15/5/23.
//  Copyright (c) 2015年 Makee. All rights reserved.
//

#import <pjsua-lib/pjsua.h>
#import "IncomingCallViewController.h"
#import "SoftPhoneDialViewController.h"
#import "RGBColorAPI.h"
#import "DWRipplesLayer.h"
#import "MyCallCollectionViewCell.h"
#import "ImageAPI.h"

@interface IncomingCallViewController ()

@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@end

@implementation IncomingCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.phoneNumberLabel.text = self.phoneNumber;
    
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
    UIColor *color1= UIColorFromHex(0x171717);//2895B4
    UIColor *color2= UIColorFromHex(0x1A212F);//42b4d5
    UIColor *color3= UIColorFromHex(0x545454);//64c1dd
    //set gradient colors
    gradientLayer.colors = @[(__bridge id)color1.CGColor, (__bridge id) color2.CGColor, (__bridge id)color3.CGColor,(__bridge id)color3.CGColor,(__bridge id) color2.CGColor,(__bridge id)color1.CGColor];
    //set locations
    gradientLayer.locations = @[@0.0, @0.3, @0.5, @0.65, @0.8, @1.0];
    //set gradient start and end points
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    
     //-----------------------添加挂断按钮------------------------
    NSArray *CellImgName = [[NSArray alloc] initWithObjects:@"hangup",@"answer", nil];
    NSArray *CellTitleName = [[NSArray alloc] initWithObjects:@"取消",@"接听", nil];
    
    MyCallCollectionViewCell  *appview=[[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
    float dr = 72;
    appview.frame=CGRectMake(kScreenWidth/2*0, kScreenHeight*0.75, kScreenWidth/2, dr+30);//100
    [self.view addSubview:appview];
    appview.tagImg.frame = CGRectMake(kScreenWidth/4-dr/2, 8, dr, dr);
    appview.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:0]];
    appview.tagLabel.frame = CGRectMake(kScreenWidth/4-50/2, dr+10, 50, 20);//width/6-50/2, 68, 50, 20
    appview.tagLabel.text = [CellTitleName objectAtIndex:0];
    appview.layer.borderWidth = 0.0f;
     //-----------------------添加接听按钮------------------------
    MyCallCollectionViewCell  *appview2=[[[NSBundle bundleForClass:[self class]]loadNibNamed:@"MyCallCollectionViewCell" owner:nil options:nil] firstObject];
    appview2.frame=CGRectMake(kScreenWidth*1/2, kScreenHeight*0.75, kScreenWidth/2, dr+30);//100
    [self.view addSubview:appview2];
    appview2.tagImg.frame = CGRectMake(kScreenWidth/4-dr/2, 8, dr, dr);
    appview2.tagImg.image = [ImageAPI imageWithName:[CellImgName objectAtIndex:1]];
    appview2.tagLabel.frame = CGRectMake(kScreenWidth/4-50/2, dr+10, 50, 20);//width/6-50/2, 68, 50, 20
    appview2.tagLabel.text = [CellTitleName objectAtIndex:1];
    appview2.layer.borderWidth = 0.0f;
    
    _phoneNumberLabel.text=self.phoneNumber;
    _userNameLabel.text=self.displayName;
    //-------------------------为点击添加监听事件------------------------
    [appview.tagBtn addTarget:self action:@selector(hangupAction:) forControlEvents:UIControlEventTouchUpInside];
    [appview2.tagBtn addTarget:self action:@selector(answerAction:) forControlEvents:UIControlEventTouchUpInside];
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
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if(state == PJSIP_INV_STATE_CONNECTING){
        NSLog(@"连接中...");
    } else if(state == PJSIP_INV_STATE_CONFIRMED) {
        NSLog(@"接听成功！");
    }
}


-(void)hangupAction:(UIButton *)sender {
    pjsua_call_hangup((pjsua_call_id)self.callId, 0, NULL, NULL);
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)answerAction:(UIButton *)sender {
    pjsua_call_answer((pjsua_call_id)self.callId, 200, NULL, NULL);
    UIStoryboard *storyBoard =  [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle bundleForClass:[self class]]];
    SoftPhoneDialViewController *viewController = [storyBoard instantiateViewControllerWithIdentifier:@"SoftPhoneDialViewController"];
    
    viewController.displayName = self.displayName;
    viewController.calleeNumber = self.phoneNumber;
    viewController.originFlag=2;
    [self presentViewController:viewController animated:YES completion:nil];
}

@end
