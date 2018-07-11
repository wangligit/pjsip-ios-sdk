//
//  DWRipplesLayer.h
//  DWRipplesLayer
//
//  Created by Duke.wu on 16/4/7.
//  Copyright © 2016年 Duke.Wu. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface DWRipplesLayer : CAReplicatorLayer

/**
 *  圆圈半径，用来确定圆圈Bounds
 */
@property (nonatomic, assign) CGFloat radius;
/**
 *  涟漪动画持续时间
 */
@property (nonatomic, assign) NSTimeInterval animationDuration;

/**
 *  开启动画
 */
- (void)startAnimation;

/**
 *  停止动画
 */
- (void)stopAnimation;

@end
