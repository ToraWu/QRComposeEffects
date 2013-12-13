//
// QR Code Generator - generates UIImage from NSString
//
// Copyright (C) 2012 http://moqod.com Andrew Kopanev <andrew@moqod.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all 
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
// PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
// DEALINGS IN THE SOFTWARE.
//

// 自定义枚举
typedef enum {
    QRPointRect = 0,
    QRPointRound
}QRPointType;

typedef enum {
    QRPositionNormal = 0,
    QRPositionRound
}QRPositionType;

typedef enum{
    CIDarkenBlendMode = 0,
    CIHueBlendMode =1,
    CIDissolveTransition = 2,
    CIExclusionBlendMode =3,
    Liquefaction

}QRfilterType;



#import <Foundation/Foundation.h>
#import "qrencode.h"

@interface QRCodeGenerator : NSObject{

    float  QRRadius;
    UIColor * QRcolor;
    UIColor *backGroundColor;
    float clearRadius;
    CGPoint clearCenter;
}


/*
 *获取二维码生成器单例
 */
//+(QRCodeGenerator*)shareInstance;

-(id)initWithRadius :(float)radius withColor:(UIColor*)color;


/*
 *设置二维码背景颜色
 *
 */

-(void)setQRBackGroundColor:(UIColor *)color;

/*
 *设置二维码清除的半径与圆心
 *
 */

-(void)setCLearRadius:(float)radius center:(CGPoint)point;


/**
 * @brief 公共方法返回一张二维码的图片。qrencode库 默认为最低等级 容错为最低L QRencodeMode 为QRMODE8
 * @param string 源字符串
   @param size 二维码中每个色块的大小 16
 * @param marginXY 二维码距离画布边界
   @param mode 二维码级别
 
 */
- (UIImage *)qrImageForString:(NSString *)string
                   withMargin:(float)marginXY
                    withMode :(int)mode
                    withOutputSize:(float)outImagesize;




- (UIImage *)qrImageForString:(NSString *)string
                  withPixSize:(float)sizeofpix
                   withMargin:(float)marginXY
                    withMode :(int)mode;
                


/**
 * @brief 公共方法返回二维码宽度 QRencodeMode 为QRMODE8，返回所需要编码的最低版本（eg:1,2,3....40）的宽度
 * @param string 源字符串
 * @param level 容错级别
 */
- (int)QRVersionForString:(NSString *)string withErrorLevel:(QRecLevel)level withMode:(int)mode;
@end
