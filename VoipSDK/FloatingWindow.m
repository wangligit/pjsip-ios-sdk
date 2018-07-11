//
//  FloatingWindow.m
//  VoipSDK
//
//  Created by wanglili on 16/11/15.
//  Copyright © 2016年 wanglili. All rights reserved.
//
#import "FloatingWindow.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAAnimation.h>
#import "ImageAPI.h"
#define WIDTH self.frame.size.width
#define HEIGHT self.frame.size.height
#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height


//static const float timeSplit = 1.f / 3.f;
@interface FloatingWindow ()<CAAnimationDelegate>
@property (nonatomic ,strong)UILabel *timeLable;
@property (nonatomic ,copy)NSString *imageNameString;
@property (nonatomic ,strong)UIView *presentView;
@property (nonatomic ,strong)CAAnimation *samllAnimation;
@property (nonatomic ,assign)BOOL isExit;
@end

@implementation FloatingWindow

//初始化缩小后的界面
-(id)initWithFrame:(CGRect)frame imageName:(NSString *)name
{
    if(self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert + 1;
        [self makeKeyAndVisible];
        _imageView = [[UIImageView alloc]initWithFrame:(CGRect){0, 0,frame.size.width, frame.size.height}];
        _imageView.image = [ImageAPI imageWithName:name];
        _imageView.alpha = 1.0;
        self.imageNameString = name;
        [self addSubview:_imageView];
        //显示时间
        UILabel *timelable = [[UILabel alloc ] initWithFrame:CGRectMake(0, 0, 60, 10)];
        timelable.center = CGPointMake(frame.size.width /2, frame.size.height / 2 + 12);
        timelable.font = [UIFont systemFontOfSize:12];
        timelable.textColor = [UIColor whiteColor];
        timelable.textAlignment = NSTextAlignmentCenter;
        timelable.text = @"等待接听";
        self.timeLable = timelable;
        [self addSubview:timelable];
        //添加移动的手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(locationChange:)];
        pan.delaysTouchesBegan = YES;
        [self addGestureRecognizer:pan];
        //添加点击的手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(click:)];
        [self addGestureRecognizer:tap];
        self.hidden = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleCallStatusChanged:)
                                                     name:@"ChattimeNotification"
                                                   object:nil];
    }
    return self;
}

- (void)handleCallStatusChanged:(NSNotification *)notification{
    //NSLog(@"++++++++++++++++++++++++notification.userinfo:%@",notification.userInfo);
    int chattime = [notification.userInfo[@"time"] intValue];
    int minutes, seconds;
    minutes = chattime/60;
    seconds = chattime%60;
    self.timeLable.text = [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
}

-(void) dealloc{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark--- 开始和结束
- (void)startWithTime:(UIView *)presentView inRect:(CGRect) rect{
    //NSLog(@"============presentView:%@=============",presentView);
    self.hidden = NO;
    _imageView.hidden = YES;
    self.timeLable.hidden = YES;
    self.startFrame = rect;
    [self circleSmallerWithView:presentView]; //最小化
    self.presentView = presentView;
}



#pragma mark ---进去和出去动画
- (void)makeIntoAnimation {
    UIImageView *showImageView = [[UIImageView alloc] init];
    showImageView.image = self.showImage;
    _imageView.hidden = YES;
    self.showImageView = showImageView;
    self.frame = self.startFrame;
    showImageView.frame = CGRectMake(0, 0, self.startFrame.size.width,self.startFrame.size.height);
    [self addSubview:showImageView];
    self.frame = self.startFrame;
    NSLog(@"+++++++++self.frame width:%f,height:%f+++++++++",self.startFrame.size.width,self.startFrame.size.height);
    [UIView animateWithDuration:0.5f animations:^{
        showImageView.frame = CGRectMake(0, 0, 76, 76);
        self.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 100, [UIScreen mainScreen].bounds.size.height - 200, 76, 76);
    } completion:^(BOOL finished) {
        showImageView.hidden = YES;
        _imageView.hidden = NO;
        _timeLable.hidden = NO;
        _imageView.image = [ImageAPI imageWithName:self.imageNameString];
    }];
}

- (void)makeOuttoAnimation {
    self.showImageView.hidden = NO;
    _imageView.hidden = YES;
    self.timeLable.hidden = YES;
    [UIView animateWithDuration:0.5f animations:^{
        self.frame = self.startFrame;
        self.showImageView.frame = CGRectMake(0, 0, self.startFrame.size.width, self.startFrame.size.height);
    } completion:^(BOOL finished) {
        self.showImageView.hidden = YES;
        [self circleBigger];
        
    }];
}


/**
 * 动画开始时
 */
- (void)animationDidStart:(CAAnimation *)theAnimation
{
    
}

/**
 * 动画结束时
 */
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    
    if (self.isExit) {
        self.isExit = NO;
        self.presentView.layer.mask = nil;
        [self.floatDelegate assistiveTocuhs];
    } else {
        //[self clipcircleImageFromView:self.presentView inRect:self.startFrame];
        [self.presentView removeFromSuperview];
        [self makeIntoAnimation];
        
    }
    
}

//最小化
- (void)circleSmallerWithView:(UIView *)view {
    NSLog(@"============view width:%f,height:%f============",kScreenWidth,kScreenHeight);
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    CGRect startFrame = self.startFrame;
    UIBezierPath *maskStartBP =  [UIBezierPath bezierPathWithOvalInRect:startFrame];
    CGFloat radius = [UIScreen mainScreen].bounds.size.height - 100;
    UIBezierPath *maskFinalBP = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(startFrame, -radius, -radius)];
    NSLog(@"原始矩形大小:%@", NSStringFromCGRect(startFrame));
    NSLog(@"dx=%f, dy=%f, CGRectInset:%@", radius,radius,NSStringFromCGRect(CGRectInset(startFrame, -radius, -radius)));
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskStartBP.CGPath;
    maskLayer.backgroundColor = (__bridge CGColorRef )([UIColor whiteColor]);
    view.layer.mask = maskLayer;
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id)(maskFinalBP.CGPath);
    maskLayerAnimation.toValue = (__bridge id)((maskStartBP.CGPath));
    //maskLayerAnimation.duration = 0.5f;
    maskLayerAnimation.duration = 0.1f;
    maskLayerAnimation.delegate = self;
    self.samllAnimation = maskLayerAnimation;
    maskLayerAnimation.removedOnCompletion = NO;
    [self addSubview:view];
    [maskLayer addAnimation:maskLayerAnimation forKey:@"path"];
}


//放大
- (void)circleBigger {
    self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    [self addSubview:self.presentView];
    UIBezierPath *maskStartBP =  [UIBezierPath bezierPathWithOvalInRect:self.startFrame];
    CGFloat radius = [UIScreen mainScreen].bounds.size.height - 100;
    UIBezierPath *maskFinalBP = [UIBezierPath bezierPathWithOvalInRect:CGRectInset(self.startFrame, -radius, -radius)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskFinalBP.CGPath;
    maskLayer.backgroundColor = (__bridge CGColorRef)([UIColor whiteColor]);
    self.presentView.layer.mask = maskLayer;
    CABasicAnimation *maskLayerAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    maskLayerAnimation.fromValue = (__bridge id)(maskStartBP.CGPath);
    maskLayerAnimation.toValue = (__bridge id)((maskFinalBP.CGPath));
    //maskLayerAnimation.duration = 0.5f;
    maskLayerAnimation.duration = 0.1f;
    maskLayerAnimation.delegate = self;
    [maskLayer addAnimation:maskLayerAnimation forKey:@"path"];
    
}





#pragma mark -触摸事件监听
-(void)locationChange:(UIPanGestureRecognizer*)p
{
    if (self.isCannotTouch) {
        return;
    }
    CGPoint panPoint = [p locationInView:[[UIApplication sharedApplication] keyWindow]];
    if(p.state == UIGestureRecognizerStateBegan)
    {
        
    }
    else if (p.state == UIGestureRecognizerStateEnded)
    {
        
    }
    if(p.state == UIGestureRecognizerStateChanged)
    {
        self.center = CGPointMake(panPoint.x, panPoint.y);
    }
    else if(p.state == UIGestureRecognizerStateEnded)
    {
        if(panPoint.x <= kScreenWidth/2)
        {
            if(panPoint.y <= 40+HEIGHT/2 && panPoint.x >= 20+WIDTH/2)
            {
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(panPoint.x, HEIGHT/2+25);
                }];
            }
            else if(panPoint.y >= kScreenHeight-HEIGHT/2-40 && panPoint.x >= 20+WIDTH/2)
            {
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(panPoint.x, kScreenHeight-HEIGHT/2-25);
                }];
            }
            else if (panPoint.x < WIDTH/2+15 && panPoint.y > kScreenHeight-HEIGHT/2)
            {
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(WIDTH/2+25, kScreenHeight-HEIGHT/2-25);
                }];
            }
            else
            {
                CGFloat pointy = panPoint.y < HEIGHT/2 ? HEIGHT/2 :panPoint.y;
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(WIDTH/2+25, pointy);
                }];
            }
        }
        else if(panPoint.x > kScreenWidth/2)
        {
            if(panPoint.y <= 40+HEIGHT/2 && panPoint.x < kScreenWidth-WIDTH/2-20 )
            {
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(panPoint.x, HEIGHT/2 + 25);
                }];
            }
            else if(panPoint.y >= kScreenHeight-40-HEIGHT/2 && panPoint.x < kScreenWidth-WIDTH/2-20)
            {
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(panPoint.x, kScreenHeight-HEIGHT/2 - 25);
                }];
            }
            else if (panPoint.x > kScreenWidth-WIDTH/2 - 15 && panPoint.y < HEIGHT/2)
            {
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(kScreenWidth-WIDTH/2 - 25, HEIGHT/2 + 25);
                }];
            }
            else
            {
                CGFloat pointy = panPoint.y > kScreenHeight-HEIGHT/2 ? kScreenHeight-HEIGHT/2 :panPoint.y;
                [UIView animateWithDuration:0.15f animations:^{
                    self.center = CGPointMake(kScreenWidth-WIDTH/2 - 25, pointy);
                }];
            }
        }
    }
}



- (void)click:(UITapGestureRecognizer*)t
{
    if (self.isCannotTouch) {
        return;
    }
    self.isExit = YES;
    [self makeOuttoAnimation];
    
}

#pragma mark -裁剪库


- (UIImage *)imageFromView:(UIView *) theView
{
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CGRectGetWidth(theView.frame),
                                                      CGRectGetHeight(theView.frame)), NO, 1);
    
    [theView drawViewHierarchyInRect:CGRectMake(0,0,
                                                CGRectGetWidth(theView.frame),
                                                CGRectGetHeight(theView.frame))
                  afterScreenUpdates:NO];
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}



-( UIImage *)getEllipseImageWithImage:(UIImage *)originImage size:(CGSize) size frame:(CGRect) rect
{
    //开启上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextFillPath(UIGraphicsGetCurrentContext());
    CGRect clip = rect;
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithOvalInRect:clip];
    [clipPath addClip];
    [originImage drawAtPoint:CGPointMake(0, 0)];
    UIImage *image;
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


- (UIImage *)clipcircleImageFromView:(UIView *)view inRect:(CGRect)frame {
    UIImage *image = [self imageFromView:view];
    UIImage *secondImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([image CGImage], frame)];
    UIImage *thirdimage = [self getEllipseImageWithImage:secondImage size:frame.size frame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    self.startFrame = frame;
    self.showImage = thirdimage;
    return thirdimage;
}

- (void)close{
    self.hidden = YES;
    self.presentView = nil;
    self.showImageView = nil;
    self.showImage = nil;
}

@end
