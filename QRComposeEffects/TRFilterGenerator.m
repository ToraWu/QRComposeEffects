//
//  TRFilterGenerator.m
//  QRComposeEffects
//
//  Created by other on 13-11-28.
//  Copyright (c) 2013年 Tora Wu. All rights reserved.
//

#import "TRFilterGenerator.h"
#pragma mark === cicontext singleton
@implementation TRContect
//=========================================================
static CIContext *ciContextSingleton = nil;

+ (CIContext *)sharedCiContextrManager {
    if (!ciContextSingleton) {
        EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        ciContextSingleton  = [CIContext contextWithEAGLContext:myEAGLContext options:nil];
    }
    
    return ciContextSingleton;
}
@end




#define pixSize 16
#define QRModeBig 14
#define QRModeNormal 7
#define QRMargin 2

#define BigImageSize (21+((QRModeBig-1)*4))*pixSize
#define SmallImageSize (21+((QRModeNormal-1)*4)+QRMargin*2)*pixSize
@implementation TRFilterGenerator


#pragma mark ====滤镜方法

/**
 * @brief 公共方法返回滤镜后的图片 CIDissolveTransition inputTime = 0.65
 * @param inputImage 源图片
 * @param targetImage 目标图片
 */
+(UIImage *)CIDissolveTransitionWithImage:(UIImage *)inputImage WithBackImage:(UIImage *)targetImage{

    CIContext *context = [TRContect sharedCiContextrManager];
    CIImage *forwardImage = [[CIImage alloc] initWithImage:inputImage];
    CIImage *inputBackImage = [[CIImage alloc] initWithImage:targetImage];
    
    CIFilter *  filter = [CIFilter filterWithName:@"CIDissolveTransition"];
    [filter setValue:forwardImage forKey:@"inputImage"];
    [filter setValue: inputBackImage forKey:@"inputTargetImage"];
    
    
    [filter setValue:[NSNumber numberWithFloat:0.65] forKey:@"inputTime"];
    
    
    CGImageRef cgiimage = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
    UIImage *newImage = [UIImage imageWithCGImage:cgiimage scale:1.0f orientation:inputImage.imageOrientation];
    CGImageRelease(cgiimage);
    return newImage;

    
}

/**
 * @brief 公共方法返回滤镜后的图片像素化 CIPixellate
 * @param inputImage 输入图片
 * @param scale 像素大小
 */
+(UIImage *)CIPixellateWithImage:(UIImage *)inputImage withInputScale:(float)scale{

    CIContext *context = [TRContect sharedCiContextrManager];
    
    CIFilter *filter= [CIFilter filterWithName:@"CIPixellate"];
    CIImage *forwardImage = [[CIImage alloc] initWithImage:inputImage];
    CIVector *vector = [CIVector vectorWithX:inputImage.size.width/2.0f Y:inputImage.size.height /2.0f];
    [filter setDefaults];
    [filter setValue:vector forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithDouble:scale] forKey:@"inputScale"];
    [filter setValue:forwardImage forKey:@"inputImage"];
    CGImageRef cgiimage = [context createCGImage:filter.outputImage fromRect:filter.outputImage.extent];
    UIImage *newImage = [UIImage imageWithCGImage:cgiimage scale:1.0f orientation:inputImage.imageOrientation];
    CGImageRef cr = CGImageCreateWithImageInRect([newImage CGImage], CGRectMake(0, 0, newImage.size.width-scale, newImage.size.height-scale));
    //    裁掉多余的一条边
	UIImage *croppedImage = [UIImage imageWithCGImage:cr];
    
    CGImageRelease(cgiimage);
    return croppedImage;

}





#pragma mark === 第一种二维码效果 像素化背景+二维码
/**
 * @brief 公共方法返回 像素化效果的二维码图片 默认容错为H 头像与二维码合成后的头片
 * @param avatarImage 头像图片作为背景
 * @param string 需要编码的字符串
   @param margin 二维码边界
   @param mode  二维码级别
   @param imageSize 输出图片的大小
 */
+(UIImage *)qrEncodeWithAatarPixellate:(UIImage *)avatarImage
                          withQRString:(NSString *)string
                            withMargin:(int)margin
                              withMode:(int)mode
                           withRadius :(float)radius
                        withOutPutSize:(float)imagSize{
    
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    int leverl = [qr QRVersionForString:string withErrorLevel:QR_ECLEVEL_H withMode:mode];
    
    int sizeOfPix = (floor)(imagSize/(leverl+2*margin));
    if (sizeOfPix%2!=0) {
        sizeOfPix --;
    }
    //生成二维码 不压缩
    UIImage *qrImage =  [qr qrImageForString:string withMargin:margin withMode:mode withOutputSize:imagSize];
    
    UIImage *newAvtarImage = [TRFilterGenerator imageWithImageSimple:avatarImage scaledToSize:(qrImage.size)];
    
    //像素化 并裁掉了多余的一个边
    newAvtarImage =  [TRFilterGenerator CIPixellateWithImage:newAvtarImage withInputScale:(sizeOfPix)];

//    滤镜合成
    UIImage *newImage = [self CIDissolveTransitionWithImage:newAvtarImage WithBackImage:qrImage];
   
    newImage = [TRFilterGenerator imageWithImageSimple:newImage scaledToSize:CGSizeMake(imagSize, imagSize)];
    return newImage;
    
}




#pragma mark === 第二种二维码效果 圆形二维码类似微信的效果
/**
 * @brief 公共方法返回 圆形二维码类似微信的效果
 * @param avatarImage 头像图片作为背景
 * @param string 需要编码的字符串
 @param margin 二维码边界
 */



+(UIImage *)qrEncodeWithCircle:(UIImage *)avatarImage withQRString:(NSString *)string withMargin:(int)margin  withRadius:(float)radius withOutPutSize:(float)imagSize{

    
    //        绘制QR背景图
    int versionNormal =  7;
    int versionBig = 14;
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    int leverl = [qr QRVersionForString:string withErrorLevel:QR_ECLEVEL_H withMode:versionBig];
    int sizeOfPix = (floor)(imagSize/(leverl));
    if (sizeOfPix%2!= 0) {
        sizeOfPix--;
    }
 
    

 
    float bigImageSize = (21+ (versionBig-1)*4) * sizeOfPix;
    float  smallImageSize = (21+ (versionNormal-1)*4) * sizeOfPix;
    
    UIImage *QRBackImage = [qr qrImageForString:string withPixSize:sizeOfPix withMargin:0 withMode:versionBig];

    
    //      绘制 真正的QR图
    UIImage *QRNormalImage = [qr qrImageForString:string withPixSize:sizeOfPix withMargin:margin withMode:versionNormal ];
  
    
    //       两张图片叠加（中间部分透明 然后将小图添加上去）
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //        float size = cirQRImage.size.width;
    CGContextRef ctx = CGBitmapContextCreate(0, bigImageSize, bigImageSize, 8, bigImageSize * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -bigImageSize);
    CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    
    CGRect touchRect = CGRectMake(0,0, bigImageSize, bigImageSize);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextDrawImage(ctx, touchRect,QRBackImage.CGImage);
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGRect Rect = CGRectMake((bigImageSize-smallImageSize)/2,(bigImageSize-smallImageSize)/2,smallImageSize, smallImageSize);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextFillRect(ctx, Rect);
    CGContextFillPath(ctx);
    
    CGContextSetBlendMode(ctx,  kCGBlendModeNormal);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextDrawImage(ctx, Rect,QRNormalImage.CGImage);
    
    CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
    
    UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
    //        切圆
    
    UIImage *cirQRImage = [TRFilterGenerator createRoundedRectImage:qrImage size:qrImage.size radius:qrImage.size.width/2];

    //      清空画布
    CGContextSetBlendMode(ctx,  kCGBlendModeClear);
    Rect = CGRectMake(0,0,bigImageSize, bigImageSize);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextFillRect(ctx, Rect);
    CGContextFillPath(ctx);
    
    //   重新绘制背景图片大小
 
    CGContextSetBlendMode(ctx,  kCGBlendModeNormal);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextDrawImage(ctx, Rect,avatarImage.CGImage);
    
    qrCGImage = CGBitmapContextCreateImage(ctx);
    
    qrImage = [UIImage imageWithCGImage:qrCGImage];
    
    // some releases
    CGContextRelease(ctx);
    CGImageRelease(qrCGImage);
    CGColorSpaceRelease(colorSpace);
    
   
    //头像像素化

    UIImage *newImage =  [TRFilterGenerator CIPixellateWithImage:qrImage withInputScale:sizeOfPix];

    //       头像圆角化
    UIImage *cirAvatarImage = [self createRoundedRectImage:newImage size:newImage.size radius:newImage.size.width/2];
    
    //滤镜合成
    
    UIImage *resultImage =   [TRFilterGenerator CIDissolveTransitionWithImage:cirAvatarImage WithBackImage:cirQRImage];
    //压缩大小
    resultImage = [TRFilterGenerator imageWithImageSimple:resultImage scaledToSize:CGSizeMake(imagSize, imagSize)];
    
    return resultImage;
   
    
}



#pragma mark ===图片压缩
//图片压缩
+(UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}
#pragma mark ===内部方法
#pragma mark ===图片圆角化处理
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth,
                                 float ovalHeight)
{
    float fw, fh;
    
    if (ovalWidth == 0 || ovalHeight == 0)
    {
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth(rect) / ovalWidth;
    fh = CGRectGetHeight(rect) / ovalHeight;
    
    CGContextMoveToPoint(context, fw, fh/2);  // Start at lower right corner
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);  // Top right corner
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1); // Top left corner
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1); // Lower left corner
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1); // Back to lower right
    
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

/*
 当r= size.width/2 时候。为最大圆
 r为圆形弧的半径
 */
+ (UIImage *)createRoundedRectImage:(UIImage*)image size:(CGSize)size radius:(NSInteger)r
{
    // the size of CGContextRef
    r = r;
    int w = size.width;
    int h = size.height;
    UIImage *img = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context2 = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);
    CGRect rect = CGRectMake(0, 0, w, h);
    
    CGContextBeginPath(context2);
    addRoundedRectToPath(context2, rect, r, r);
    CGContextClosePath(context2);
    CGContextClip(context2);
    CGContextDrawImage(context2, CGRectMake(0, 0, w, h), img.CGImage);
    CGImageRef imageMasked = CGBitmapContextCreateImage(context2);
    img = [UIImage imageWithCGImage:imageMasked];
    
    CGContextRelease(context2);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageMasked);
    
    return img;
}
@end
