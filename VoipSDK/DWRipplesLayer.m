//
//  DWRipplesLayer.m
//  DWRipplesLayer
//
//  Created by Duke.wu on 16/4/7.
//  Copyright © 2016年 Duke.Wu. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "DWRipplesLayer.h"

@interface DWRipplesLayer ()
/**
 *  涟漪圈
 */
@property (nonatomic, strong) CALayer *roundLayer;

/**
 *  动画组
 */
@property (nonatomic, strong) CAAnimationGroup *ripplesAnimationGroup;

/**
 *  涟漪圈半径的初始值
 */
@property (nonatomic, assign) CGFloat fromValueForRadius;

/**
 *  涟漪圈Alpha初始值
 */
@property (nonatomic, assign) CGFloat fromValueForAlpha;

@end

@implementation DWRipplesLayer

- (instancetype)init{
  if (self = [super init]) {
    [self addSublayer:self.roundLayer];
    [self setUp];
  }
  return self;
}


#pragma mark - Public Methods

- (void)startAnimation{
  [self setUpAnimation];
  [self.roundLayer addAnimation:self.ripplesAnimationGroup forKey:@"ripples"];
}

#pragma mark - Public Methods

-(void)stopAnimation{
    //[self.roundLayer removeAllAnimations];
    [self.roundLayer removeAnimationForKey:@"ripples"];
}

#pragma mark - Private Methods

- (void)setUp{

  self.roundLayer.backgroundColor = [[UIColor whiteColor] CGColor];
  
  self.radius = 90;
  self.animationDuration = 3;
  self.fromValueForAlpha = 0.f;
  self.fromValueForRadius = 0.1f;
  
  // 必须 CAReplicatorLayer的重要特性
  self.repeatCount = INFINITY;
  self.instanceCount = 3;
  self.instanceDelay = 1;
}

- (void)setUpAnimation{
  
  self.ripplesAnimationGroup.duration = self.animationDuration;
  self.ripplesAnimationGroup.repeatCount = self.repeatCount;
  
  // 动画曲线，使用默认
  self.ripplesAnimationGroup.timingFunction =  [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];;
  
  // 圆圈放大
  CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
  scaleAnimation.fromValue = @(self.fromValueForRadius);
  scaleAnimation.toValue = @1.0;
  scaleAnimation.duration = self.animationDuration;
  
  // 改变 alpha (关键帧动画)
  CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
  opacityAnimation.values = @[@(self.fromValueForAlpha), @0.5, @0];
  opacityAnimation.keyTimes = @[@0, @(0.4), @1];
  opacityAnimation.duration = self.animationDuration;
  
  self.ripplesAnimationGroup.animations = @[scaleAnimation, opacityAnimation];
}


#pragma mark - setter

- (void)setRadius:(CGFloat)radius{
  _radius = radius;
  CGFloat roundW = radius*2;
  self.roundLayer.bounds = CGRectMake(0, 0, roundW, roundW);
  self.roundLayer.cornerRadius = radius;
}

#pragma mark - getter

- (CALayer *)roundLayer{
  if (!_roundLayer) {
    _roundLayer = [CALayer new];
    // 适应屏幕的分辨率
    _roundLayer.contentsScale = [UIScreen mainScreen].scale;
    _roundLayer.opacity = 0;
  }
  return _roundLayer;
}

- (CAAnimationGroup *)ripplesAnimationGroup{
  if (!_ripplesAnimationGroup) {
    _ripplesAnimationGroup = [CAAnimationGroup animation];
  }
  return _ripplesAnimationGroup;
}

@end













