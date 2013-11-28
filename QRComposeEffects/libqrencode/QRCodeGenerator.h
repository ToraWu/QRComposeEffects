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

@interface QRCodeGenerator : NSObject
@property (nonatomic,assign) float  QRRadious;
@property (nonatomic,strong) UIColor * QRcolor;




/*
 *获取二维码生成器单例
 */
+(QRCodeGenerator*)shareInstance;

/**
 * @brief 公共方法返回一张二维码的图片。qrencode库 默认为最低等级 容错为最低L QRencodeMode 为QRMODE8
 * @param string 源字符串
 @param size 二维码图片尺寸= 宽 = 长
 * @param marginXY 二维码距离画布边界
 */
- (UIImage *)qrImageForString:(NSString *)string imageSize:(CGFloat)size withMargin:(float)marginXY;


/**
 * @brief 公共方法返回 字符串，容错为最低L QRencodeMode 为QRMODE8，返回所需要编码的最低版本（eg:1,2,3....40）
 * @param string 源字符串
 * @param level 容错级别
 */
- (int)QRVersionForString:(NSString *)string withErrorLevel:(QRecLevel)level;
@end
