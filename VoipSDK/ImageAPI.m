//
//  ImageAPI.m
//  VoipSDK
//
//  Created by wanglili on 16/11/29.
//  Copyright © 2016年 wanglili. All rights reserved.
//

#import "ImageAPI.h"

@implementation ImageAPI

+(UIImage*) imageWithName:(NSString*) name{
    NSBundle* bun = [NSBundle bundleForClass: self];
    NSString*path = [bun pathForResource:[NSString stringWithFormat:@"icons/%@",name] ofType:@"png"];
    return [UIImage imageWithContentsOfFile: path];
}

@end
