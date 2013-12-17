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

typedef enum {
    QRECCLevelLow = 0,
    QRECCLevelMedium = 1,
    QRECCLevelQuality = 2,
    QRECCLevelHigh = 3
    
}QRECCLevel;


#import <Foundation/Foundation.h>
#import "qrencode.h"

@interface QRCodeGenerator : NSObject{

    float  QRRadius;//液化半径 0-1
    UIColor * QRcolor; //QR 颜色
    UIColor *backGroundColor;//QR背景颜色
    float clearRadius;// QR不需要绘制区域的半径
    CGPoint clearCenter;//QR不需要绘制区域的中心
    
    BOOL isRoundPixel;
}

/*
 * 工具方法，给定二维码版本（version）计算生成的二维码矩阵大小
 */
+ (NSInteger)matrixSizeOfQRVersion:(NSInteger)version margin:(NSInteger)margin;

/**
 * @brief 公共方法返回二维码宽度 QRencodeMode 为QRMODE8，返回所需要编码的最低版本（eg:1,2,3....40）的宽度
 * @param string 源字符串
 * @param level 容错级别
 */
- (int)QRVersionForString:(NSString *)string withErrorLevel:(QRecLevel)level withMode:(int)mode;

/*
 *获取二维码生成器单例
 */
//+(QRCodeGenerator*)shareInstance;

-(id)initWithRadius :(float)radius withColor:(UIColor*)color;



/*
 *设置是否是需要像素点圆角化绘制
 */

-(void)setIsRoundPixel:(BOOL)isRound;
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
                   Margin:(float)marginXY
                    Mode :(int)mode
                    OutputSize:(float)outImagesize;



/**
 * @brief 公共方法返回一张二维码的图片。此方法仅供二维码像素滤镜时调用
 * @param string 源字符串
 * @param size 二维码中每个色块的大小 16
 * @param marginXY 二维码距离画布边界
 * @param mode 二维码级别
 * @param outImageSize 输出二维码图片的大小
 
 */
- (UIImage *)qrImageForPixelString:(NSString *)string
                  PixSize:(float)sizeofpix
                   Margin:(float)marginXY
                    Mode :(int)mode
                        outPutSize: (float)outImageSize;



@end
