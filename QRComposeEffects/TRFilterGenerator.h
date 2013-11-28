//
//  TRFilterGenerator.h
//  QRComposeEffects
//
//  Created by other on 13-11-28.
//  Copyright (c) 2013年 Tora Wu. All rights reserved.
//

@interface TRContect : NSObject
+ (CIContext *)sharedCiContextrManager ;
@end
#import <Foundation/Foundation.h>
#import "QRCodeGenerator.h"

@interface TRFilterGenerator : NSObject


/**
 * @brief 公共方法返回滤镜后的图片像素化 CIPixellate
 * @param inputImage 输入图片
 * @param scale 像素大小
 */
+(UIImage *)CIPixellateWithImage:(UIImage *)inputImage withInputScale:(float)scale;

/**
 * @brief 公共方法返回滤镜后的图片 CIDissolveTransition inputTime = 0.65
 * @param inputImage 源图片
 * @param targetImage 目标图片
 */
+(UIImage *)CIDissolveTransitionWithImage:(UIImage *)inputImage WithBackImage:(UIImage *)backImage;

/**
 * @brief 公共方法返回 像素化效果的二维码图片 默认容错为H 头像与二维码合成后的头片
 * @param avatarImage 头像图片作为背景
 * @param string 需要编码的字符串
 @param margin 二维码边界
 */

+(UIImage *)qrEncodeWithAatarPixellate:(UIImage *)avatarImage withQRString:(NSString *)string withMargin:(int)margin  withMode:(int)mode;




/**
 * @brief 公共方法返回 圆形二维码类似微信的效果
 * @param avatarImage 头像图片作为背景
 * @param string 需要编码的字符串
 @param margin 二维码边界
 */

+(UIImage *)qrEncodeWithCircle:(UIImage *)avatarImage withQRString:(NSString *)string withMargin:(int)margin;


/*
 *图片压缩
 */
+(UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize;

/*
 *圆角化
 */
+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size radius:(NSInteger)r;
@end
