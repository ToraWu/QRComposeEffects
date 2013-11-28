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

+(UIImage *)CIPixellateWithImage:(UIImage *)inputImage withInputScale:(float)scale;


+(UIImage *)CIDissolveTransitionWithImage:(UIImage *)inputImage WithBackImage:(UIImage *)backImage;

/**
 * @brief 公共方法返回像素化效果的二维码图片 默认容错为H
 * @param inputImage 头像图片作为背景
 * @param scale 需要编码的字符串
 */
+(UIImage *)qrEncodeWithAatarPixellate:(UIImage *)avatarImage withQRString:(NSString *)string;

+(UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize;

@end
