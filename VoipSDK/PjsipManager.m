//
//  PjsipManager.m
//  VoipSDK
//
//  Created by wanglili on 17/3/13.
//  Copyright © 2017年 wanglili. All rights reserved.
//

#import "PjsipManager.h"
#import <pjsua-lib/pjsua.h>
#import "Utility.h"
#import "WiFiUtils.h"
#import <AVFoundation/AVFoundation.h>

@interface PjsipManager() {
    pjsua_call_id _call_id;//call_id是用来区分哪个号码打进来的
    pjsua_acc_id _acc_id;
}


@end

@implementation PjsipManager

+ (instancetype)sharedPjsipManager {
    static PjsipManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (int)pjsipInit:(NSString *) user password:(NSString *) pwd server:(NSString *) addr proxy:(NSString *) proxy {
    pj_status_t status;
    
    status = pjsua_destroy();
    if (status != PJ_SUCCESS) {
        NSLog(@"error destroy pjsua");
        return 500;
    }
    
    // 创建SUA
    status = pjsua_create();
    
    if (status != PJ_SUCCESS) {
        NSLog(@"error create pjsua");
        return 500;
    }
    
    {
        // SUA 相关配置
        pjsua_config cfg;
        pjsua_media_config media_cfg;
        pjsua_logging_config log_cfg;
        
        pjsua_config_default(&cfg);
        
        //cfg.outbound_proxy_cnt = 1;
        //cfg.outbound_proxy[0] = pj_str((char *)[NSString stringWithFormat:@"sip:%@:5060;transport=tcp",proxy].UTF8String);
        
        // 回调函数配置
        cfg.cb.on_incoming_call = &on_incoming_call;            // 来电回调
        cfg.cb.on_call_media_state = &on_call_media_state;      // 媒体状态回调（通话建立后，要播放RTP流）
        cfg.cb.on_call_state = &on_call_state;                  // 电话状态回调
        
        // 媒体相关配置
        pjsua_media_config_default(&media_cfg);
        
        // 日志相关配置
        pjsua_logging_config_default(&log_cfg);
#ifdef DEBUG
        log_cfg.msg_logging = PJ_TRUE;
        log_cfg.console_level = 4;
        log_cfg.level = 5;
#else
        log_cfg.msg_logging = PJ_FALSE;
        log_cfg.console_level = 0;
        log_cfg.level = 0;
#endif
        
        // 初始化PJSUA
        status = pjsua_init(&cfg, &log_cfg, &media_cfg);
        if (status != PJ_SUCCESS) {
            NSLog(@"error init pjsua");
            return 500;
        }
    }
    
    // udp transport
    {
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
        // 传输类型配置
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"error add udp transport for pjsua");
            return 500;
        }
    }
    
    // Add TCP transport. background mode required!!!
    /*{
     // Init transport config structure
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
        cfg.port = 5060;
     
        // Add TCP transport.
        status = pjsua_transport_create(PJSIP_TRANSPORT_TCP, &cfg,NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"error creating TCP transport for pjsua");
            return;
        }
     }*/
    
    /* Initialization is done, now start pjsua */
    // 启动PJSUA
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSLog(@"error start pjsua");
        return 500;
    }
    
    /* Register to SIP server by creating SIP account. */
    {
        
        pjsua_acc_id acc_id;
        pjsua_acc_config cfg;
        pjsua_acc_config_default(&cfg);
        cfg.id = pj_str((char *)[NSString stringWithFormat:@"sip:%@@%@", user, addr].UTF8String);
        cfg.reg_uri = pj_str((char *)[NSString stringWithFormat:@"sip:%@", addr].UTF8String);
        cfg.reg_retry_interval = 0;
        cfg.cred_count = 1;
        cfg.cred_info[0].realm = pj_str("*");
        cfg.cred_info[0].username = pj_str((char *)user.UTF8String);
        cfg.cred_info[0].data_type = PJSIP_CRED_DATA_PLAIN_PASSWD;
        cfg.cred_info[0].data = pj_str((char *)pwd.UTF8String);
        
        //pn-type=acme;pn-methods="INVITE";
        //pn-uri="https://pn.acme.example.com/ZTY4ZDJlMzODE1NmUgKi0K"
        //cfg.reg_contact_params;
        
        /*
        //PJSIP与pushkit集成
        struct pjsip_generic_string_hdr CustomHeader;
        pj_str_t name = pj_str("pn-type");
        pj_str_t value = pj_str("acme");
        pjsip_generic_string_hdr_init2(&CustomHeader, &name, &value);
        pj_list_push_back(&cfg.reg_hdr_list, &CustomHeader);

        struct pjsip_generic_string_hdr header;
        name = pj_str("pn-methods");
        value = pj_str("INVITE");
        pjsip_generic_string_hdr_init2(&header, &name, &value);
        pj_list_push_back(&cfg.reg_hdr_list, &header);
        
        struct pjsip_generic_string_hdr reg_header;
        name = pj_str("pn-uri");
        value = pj_str("https://pn.acme.example.com/ZTY4ZDJlMzODE1NmUgKi0K");
        pjsip_generic_string_hdr_init2(&reg_header, &name, &value);
        pj_list_push_back(&cfg.reg_hdr_list, &reg_header);
        */
        
        
        if (![Utility isBlankString:proxy]) {
            cfg.proxy[cfg.proxy_cnt++] = pj_str((char *)[NSString stringWithFormat:@"sip:%@",proxy].UTF8String);
        }

        pj_status_t status = pjsua_acc_add(&cfg, PJ_TRUE, &acc_id);
        
        if (status != PJ_SUCCESS) {
            NSString *errorMessage = [NSString stringWithFormat:@"注册失败, 返回错误号:%d!", status];
            NSLog(@"register error: %@", errorMessage);
            return 500;
        }
        
    }
    
    /* Simply sleep for 5s, give the time for library to send transport
     * keepalive packet, and wait for server response if any. Don't sleep
     * too short, to avoid too many wakeups, because when there is any
     * response from server, app will be woken up again (see also #1482).
     */
    pj_thread_sleep(1000);
    return 0;
}

static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    NSLog(@"-------------incomingCall---------------");
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    NSString *remote_info = [NSString stringWithUTF8String:ci.remote_info.ptr];
    NSUInteger startIndex = [remote_info rangeOfString:@"<"].location;
    NSUInteger endIndex = [remote_info rangeOfString:@">"].location;
    NSString *remote_address = [remote_info substringWithRange:NSMakeRange(startIndex + 1, endIndex - startIndex - 1)];
    remote_address = [remote_address componentsSeparatedByString:@":"][1];
    id argument = @{
                    @"call_id"          : @(call_id),
                    @"remote_address"   : remote_address
                    };
    
    /* Automatically answer incoming calls with 180/ringing */
    pjsua_call_answer(call_id, 180, NULL, NULL);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPIncomingCallNotification" object:nil userInfo:argument];
    });
}

static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    NSLog(@"<<<<<<<<<<< on_call_state:call_id: %d >>>>>>>>>>",call_id);
    id argument = @{
                    @"call_id"  : @(call_id),
                    @"state"    : @(ci.state)
                    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPCallStatusChangedNotification" object:nil userInfo:argument];
    });
}

static void on_call_media_state(pjsua_call_id call_id) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

- (void)makeCall:(NSString *)callNumber server:(NSString *) addr {
    NSString *targetUri = [NSString stringWithFormat:@"sip:%@@%@",callNumber, addr];
    
    pj_status_t status;
    pj_str_t dest_uri = pj_str((char *)targetUri.UTF8String);
    status = pjsua_call_make_call(_acc_id, &dest_uri, 0, NULL, NULL, &_call_id);
    
    if (status != PJ_SUCCESS) {
        char  errMessage[PJ_ERR_MSG_SIZE];
        pj_strerror(status, errMessage, sizeof(errMessage));
        NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
    }
}

- (void)hangup {
    pj_status_t status = pjsua_call_hangup(_call_id, 0, NULL, NULL);
    
    if (status != PJ_SUCCESS) {
        const pj_str_t *statusText =  pjsip_get_status_text(status);
        NSLog(@"挂断错误, 错误信息:%d(%s) !", status, statusText->ptr);
    }

}

- (void)answerCall {
    pj_status_t status = pjsua_call_answer(_call_id, 200, NULL, NULL);
    if (status != PJ_SUCCESS) {
        const pj_str_t *statusText =  pjsip_get_status_text(status);
        NSLog(@"接听错误, 错误信息:%d(%s) !", status, statusText->ptr);
    }
}

- (void)systemMakeCall:(NSString *) callNumber {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //获取目标号码字符串,转换成URL
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",callNumber]];
        //调用系统方法拨号
        [[UIApplication sharedApplication] openURL:url];
    });
}

-(int)makeCall:(NSString *)callNumber server:(NSString *) addr customHeader:(NSDictionary *) headers{
    
    NSString *targetUri = [NSString stringWithFormat:@"sip:%@@%@",callNumber, addr];
    pj_str_t dest_uri = pj_str((char *)targetUri.UTF8String);
    
   /*添加自定义头部*/
    pj_caching_pool cp;
    pj_pool_t *pool;
    pj_status_t status = PJ_SUCCESS;
    
    pjsua_msg_data msg_data;
    pjsua_msg_data_init(&msg_data);
    
    
    pj_caching_pool_init(&cp, &pj_pool_factory_default_policy, 0);
    pool= pj_pool_create(&cp.factory, "header", 1000, 1000, NULL);
    
    for(NSString *key in [headers allKeys]){
        
        NSLog(@"Call.m key value in call %@,%@",key,[headers objectForKey:key] );
        pj_str_t hname = pj_str((char *)[key UTF8String]);
        char * headerValue=(char *)[(NSString *)[headers objectForKey:key] UTF8String];
        pj_str_t hvalue = pj_str(headerValue);
        pjsip_generic_string_hdr* add_hdr = pjsip_generic_string_hdr_create(pool, &hname, &hvalue);
        pj_list_push_back(&msg_data.hdr_list, add_hdr);
    }
    status = pjsua_call_make_call(_acc_id, &dest_uri, 0, NULL, &msg_data, &_call_id);
    pj_pool_release(pool);
    
    if (status != PJ_SUCCESS) {
        char  errMessage[PJ_ERR_MSG_SIZE];
        pj_strerror(status, errMessage, sizeof(errMessage));
        NSLog(@"外拨错误, 错误信息:%d(%s) !", status, errMessage);
        return 500;
    }
    return 0;
}

- (void)Microphone:(BOOL)ABool{
    if (ABool) {
        pjsua_conf_adjust_rx_level(0, 1);
    } else {
        pjsua_conf_adjust_rx_level(0, 0);
    }
}

- (void)setISSpeaker:(BOOL)isSpeaker{
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

- (void)sendDTMFDigits:(NSString *)digitsStr{
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

@end
