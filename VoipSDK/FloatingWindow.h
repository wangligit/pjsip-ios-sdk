//
//  FloatingWindow.h
//  VoipSDK
//
//  Created by wanglili on 16/11/15.
//  Copyright © 2016年 wanglili. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol FloatingWindowTouchDelegate <NSObject>
//悬浮窗点击事件
- (void)assistiveTocuhs;
@end

@interface FloatingWindow : UIWindow
{
    UIImageView *_imageView;
}

@property(nonatomic ,strong)UIImage *showImage;
@property(nonatomic ,strong)UIImageView *showImageView;
@property(nonatomic ,assign)CGRect startFrame;
@property(nonatomic ,assign)BOOL isCannotTouch;

@property(nonatomic ,strong)id<FloatingWindowTouchDelegate> floatDelegate;

- (id)initWithFrame:(CGRect)frame imageName:(NSString*)name;

- (void)startWithTime:(UIView *)presentView inRect:(CGRect) rect;

- (UIImage *)clipcircleImageFromView:(UIView *)view inRect:(CGRect) frame;

- (void)close;

@end




