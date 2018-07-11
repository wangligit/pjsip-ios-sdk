//
//  MyCallCollectionViewCell.h
//  VoipSDK
//
//  Created by wanglili on 16/12/21.
//  Copyright © 2016年 wanglili. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyCallCollectionViewCell : UICollectionViewCell


@property (strong, nonatomic) IBOutlet UIImageView *tagImg;
@property (strong, nonatomic) IBOutlet UILabel *tagLabel;

@property (strong, nonatomic) IBOutlet UIButton *tagBtn;

@end
