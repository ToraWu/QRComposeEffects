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

/**
 * 带面部识别的波普艺术二维码
 *
 */
+ (UIImage *)popartWithFaceDetectFromImage:(UIImage *)inputImage
                          maskWithQRString:(NSString *)string
                                    margin:(int)margin
                                    radius:(float)radius
                                   version:(int)qrVersion
                                outPutSize:(float)imageSize
                                     color:(UIColor *)color {
    
    CIImage *scrImage = [CIImage imageWithCGImage:[TRFilterGenerator imageWithImageSimple:inputImage backGroundColor:nil newSize:CGSizeMake(inputImage.size.width, inputImage.size.height)].CGImage];
    
    CIImage *printmakingResult = [self ciImagePrintmaikingWithImage:scrImage color:[CIColor colorWithCGColor:color.CGColor] needBrighten:YES];
    
    printmakingResult = [self popartImageWithCIImage:printmakingResult
                                            color0:[CIColor colorWithCGColor:color.CGColor]
                                            color1:[CIColor colorWithCGColor:[self brightColorFromOrignalColor:color].CGColor]];
    
    // Generate QRcode image
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:color];
    
    BOOL faceDeteced = [self configureQRGeneratorToReduceFace:qr inputImage:scrImage outputSize:imageSize];
    
    CIImage *qrImage = [CIImage imageWithCGImage:[qr qrImageForString:string Margin:margin Mode:qrVersion OutputSize:imageSize].CGImage];
    
    // Composite
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setValue:qrImage forKey:@"inputImage"];
    [filter setValue:printmakingResult forKey:@"inputBackgroundImage"];
    
    CIImage *compositedImage = [filter valueForKey:kCIOutputImageKey];
    
    //compositedImage = [self borderedImageWithImage:compositedImage outputSize:imageSize inset:(imageSize / [QRCodeGenerator matrixSizeOfQRVersion:qrVersion margin:margin]) color:color];
    
    // Output UIImage
    return [self outputUIImageFromCIImage:compositedImage rectangle:CGRectMake(0, 0, imageSize, imageSize)];
}


/**
 * 在中央区域显示图像的波普艺术二维码
 *
 */
+ (UIImage *)popartWithImageInCenter:(UIImage *)inputImage
                    maskWithQRString:(NSString *)string
                              margin:(int)margin
                              radius:(float)radius
                             version:(int)qrVersion
                          outPutSize:(float)imageSize
                              color0:(UIColor *)color0
                              color1:(UIColor *)color1
                           maskImage:(UIImage *)maskImage
                     maskBorderImage:(UIImage *)maskBorderImage {
    
    CIImage *scrImage = [CIImage imageWithCGImage:[TRFilterGenerator imageWithImageSimple:inputImage backGroundColor:nil newSize:CGSizeMake(inputImage.size.width, inputImage.size.height)].CGImage];
    
    CIImage *printmakingResult = [self ciImagePrintmaikingWithImage:scrImage color:[CIColor colorWithString:@"[0 0 0 1]"] needBrighten:NO];
    
    
    // Generate QRcode image
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:[UIColor blackColor]];
    
    CIImage *qrImage = [CIImage imageWithCGImage:[qr qrImageForString:string Margin:margin Mode:qrVersion OutputSize:imageSize].CGImage];
    
    // Mask userImage with mask shape
    if (maskImage && maskBorderImage) {
        UIImage *rescaledMaskImage = [self imageWithImageSimple:maskImage backGroundColor:[UIColor clearColor] newSize:CGSizeMake(imageSize, imageSize)];
        CIFilter *maskFilter = [CIFilter filterWithName:@"CISourceInCompositing"];
        [maskFilter setValue:[CIImage imageWithCGImage:rescaledMaskImage.CGImage] forKey:@"inputBackgroundImage"];
        [maskFilter setValue:printmakingResult forKey:@"inputImage"];
        printmakingResult = maskFilter.outputImage;
        
        UIImage *rescaledMaskBorderImage = [self imageWithImageSimple:maskBorderImage backGroundColor:[UIColor clearColor] newSize:CGSizeMake(imageSize, imageSize)];
        CIFilter *overFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [overFilter setValue:[CIImage imageWithCGImage:rescaledMaskBorderImage.CGImage] forKey:kCIInputImageKey];
        [overFilter setValue:printmakingResult forKey:@"inputBackgroundImage"];
        printmakingResult = overFilter.outputImage;
        
    }
    
    // scale the image into a square on the center of qr code.
    
    NSInteger qrSize = [QRCodeGenerator matrixSizeOfQRVersion:qrVersion margin:margin];
    long int properScaledSize = lround(qrSize * 0.4);
    if (properScaledSize%2 == 0) {
        properScaledSize += 1;
    }
    CGFloat scaleFactor = (CGFloat)properScaledSize/qrSize;
    
    
//    CIFilter *transformFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
//    [transformFilter setValue:printmakingResult forKey:kCIInputImageKey];
//    CGFloat originX = imageSize * (1-scaleFactor) * 0.5;
//    CGFloat originY = imageSize * (1-scaleFactor) * 0.5;
//    CGFloat width = imageSize * scaleFactor;
//    CGFloat height = imageSize * scaleFactor;
//    [transformFilter setValue:[CIVector vectorWithX:originX Y:originY] forKey:@"inputBottomLeft"];
//    [transformFilter setValue:[CIVector vectorWithX:originX + width Y:originY] forKey:@"inputBottomRight"];
//    [transformFilter setValue:[CIVector vectorWithX:originX + width Y:originY + height] forKey:@"inputTopRight"];
//    [transformFilter setValue:[CIVector vectorWithX:originX Y:originY + height] forKey:@"inputTopLeft"];
//    CIImage *scaledResult = [transformFilter valueForKey:kCIOutputImageKey];
    
    
    CIFilter *transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
    CGAffineTransform xform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
    xform = CGAffineTransformTranslate(xform, imageSize*(1-scaleFactor)*0.5/scaleFactor, imageSize*(1-scaleFactor)*0.5/scaleFactor);
    [transformFilter setValue:[NSValue valueWithBytes:&xform
                                             objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    [transformFilter setValue:printmakingResult forKey:kCIInputImageKey];
    CIImage *scaledResult = [transformFilter valueForKey:kCIOutputImageKey];
    
    printmakingResult = scaledResult;
    
    // Source out rect of scaled image from qr.
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOutCompositing"];
    [filter setValue:qrImage forKey:@"inputImage"];
    [filter setValue:scaledResult forKey:@"inputBackgroundImage"];
    qrImage = [filter valueForKey:kCIOutputImageKey];
    
    //background printmakingResult with a default white color.
    CIFilter *colorGenerateFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"
                                               keysAndValues:kCIInputColorKey, [CIColor colorWithString:@"1 1 1 1"], nil];
    CIImage *whiteBG = [colorGenerateFilter valueForKey:kCIOutputImageKey];
    
    // Source out rect of scaled image from qr.
    CIFilter *atopFilter = [CIFilter filterWithName:@"CISourceAtopCompositing"];
    [atopFilter setValue:printmakingResult forKey:@"inputImage"];
    [atopFilter setValue:whiteBG forKey:@"inputBackgroundImage"];
    printmakingResult = [atopFilter valueForKey:kCIOutputImageKey];
    
    // Composite
    CIFilter *SourceOverFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [SourceOverFilter setValue:qrImage forKey:@"inputImage"];
    [SourceOverFilter setValue:printmakingResult forKey:@"inputBackgroundImage"];
    
    CIImage *compositedImage = [SourceOverFilter valueForKey:kCIOutputImageKey];
    
    compositedImage = [self borderedImageWithImage:compositedImage outputSize:imageSize inset:(imageSize / [QRCodeGenerator matrixSizeOfQRVersion:qrVersion margin:margin]) color:[UIColor blackColor]];
    
    if (color1) {
        // !!Important: output once to ACTUALLY run the filters.
        UIImage *compositedUIImage = [self outputUIImageFromCIImage:compositedImage rectangle:CGRectMake(0, 0, imageSize, imageSize)];
        
        // False Color
        CIFilter *falseColorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [falseColorFilter setValue:[CIImage imageWithCGImage:compositedUIImage.CGImage] forKey:kCIInputImageKey];
        [falseColorFilter setValue:[CIColor colorWithCGColor:color0.CGColor] forKey:@"inputColor0"];
        [falseColorFilter setValue:[CIColor colorWithString:@"1 1 1 1"] forKey:@"inputColor1"];
        CIImage *resultImage0 = [falseColorFilter valueForKey:kCIOutputImageKey];
        
        CIFilter *falseColorFilter1 = [CIFilter filterWithName:@"CIFalseColor"];
        [falseColorFilter1 setValue:[CIImage imageWithCGImage:compositedUIImage.CGImage] forKey:kCIInputImageKey];
        [falseColorFilter1 setValue:[CIColor colorWithCGColor:color1.CGColor] forKey:@"inputColor0"];
        [falseColorFilter1 setValue:[CIColor colorWithString:@"1 1 1 1"] forKey:@"inputColor1"];
        CIImage *resultImage1 = [falseColorFilter1 valueForKey:kCIOutputImageKey];
        
        // Radient transition
        // !!The 2 sources of transition must use images origined from different source.
        CIFilter *transition = [CIFilter filterWithName:@"CISwipeTransition"
                                          keysAndValues:
                                @"inputImage", resultImage0,
                                @"inputTargetImage", resultImage1,
                                @"inputExtent", [CIVector vectorWithX:0 Y:0 Z:imageSize W:imageSize*0.667],
                                @"inputColor", [CIColor colorWithRed:0 green:0 blue:0 alpha:0],
                                @"inputAngle", @(0.5 * M_PI),
                                @"inputWidth", @(imageSize * 0.333),
                                @"inputOpacity", @0,
                                @"inputTime", @0.5,
                                nil];
        
        compositedImage = [transition valueForKey:kCIOutputImageKey];
        
    } else {
        
        // False Color
        CIFilter *falseColorFilter = [CIFilter filterWithName:@"CIFalseColor"];
        [falseColorFilter setValue:compositedImage forKey:kCIInputImageKey];
        [falseColorFilter setValue:[CIColor colorWithCGColor:color0.CGColor] forKey:@"inputColor0"];
        [falseColorFilter setValue:[CIColor colorWithString:@"1 1 1 1"] forKey:@"inputColor1"];
        compositedImage = [falseColorFilter valueForKey:kCIOutputImageKey];
    }
    
    
    // Output UIImage
    return [self outputUIImageFromCIImage:compositedImage rectangle:CGRectMake(0, 0, imageSize, imageSize)];

}

/**
 * @brief 公共方法返回 像素化效果的二维码图片 默认容错为H 头像与二维码合成后的头片
 * @param avatarImage 头像图片作为背景
 * @param string 需要编码的字符串
   @param margin 二维码边界
   @param mode  二维码级别
   @param imageSize 输出图片的大小
 */
+(UIImage *)qrEncodeWithAatarPixellate:(UIImage *)avatarImage
                              qRString:(NSString *)string
                                margin:(int)margin
                                  mode:(int)mode
                               radius :(float)radius
                            outPutSize:(float)imageSize
                               qRColor:(UIColor*)color
{
    
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:color];
    int leverl = [qr QRVersionForString:string withErrorLevel:QR_ECLEVEL_H withMode:mode];
    
    int sizeOfPix = (floor)(imageSize/(leverl+2*margin));
    if (sizeOfPix%2!=0) {
        sizeOfPix --;
    }
    
    //测试：生成圆点型的二维码
    //[qr setIsRoundPixel:YES];
    
    //测试：如果识别出面部，配置面部减码
    //[self configureQRGeneratorToReduceFace:qr inputImage:[CIImage imageWithCGImage:avatarImage.CGImage] outputSize:imageSize];
    
    //生成二维码 不压缩
    UIImage *qrImage = [qr qrImageForPixelString:string
                                         PixSize:sizeOfPix
                                          Margin:margin
                                        Mode:mode
                                        outPutSize:imageSize];
    
    UIImage *newAvtarImage = [TRFilterGenerator imageWithImageSimple:avatarImage backGroundColor:nil newSize:qrImage.size];
    
    
    //像素化 并裁掉了多余的一个边
    newAvtarImage =  [TRFilterGenerator CIPixellateWithImage:newAvtarImage withInputScale:(sizeOfPix)];
    qrImage = [self imageWithImageSimple:qrImage backGroundColor:[UIColor whiteColor] newSize:newAvtarImage.size];

    //滤镜合成
    UIImage *newImage = [self CIDissolveTransitionWithImage:newAvtarImage WithBackImage:qrImage];
    
//    newImage = [TRFilterGenerator imageWithImageSimple:newImage backGroundColor:[UIColor whiteColor] newSize:CGSizeMake(imageSize, imageSize)];
    
    CIImage *resultImage = [CIImage imageWithCGImage:newImage.CGImage];
    
    UIImage *textureUIImage = [UIImage imageNamed:@"2.png"];
    //CGFloat blockSize = (CGFloat)imageSize/[QRCodeGenerator matrixSizeOfQRVersion:mode margin:margin];
    CGFloat textureSize = 3*sizeOfPix;
    textureUIImage = [self imageWithImageSimple:textureUIImage backGroundColor:nil newSize:CGSizeMake(textureSize, textureSize)];
    CIImage *textureImage = [CIImage imageWithCGImage:textureUIImage.CGImage];
    resultImage = [self texturedImageWithCIImage:resultImage color:nil textureImage:textureImage];
    
    // 修改为输出尺寸
    newImage = [self outputUIImageFromCIImage:resultImage rectangle:CGRectMake(0, 0, newImage.size.width, newImage.size.height)];
    
    newImage = [self imageWithImageSimple:newImage backGroundColor:[UIColor whiteColor] newSize:CGSizeMake(imageSize, imageSize)];
    
    return newImage;
    
}

/**
 * @brief 公共方法返回 圆形二维码类似微信的效果
 * @param avatarImage 头像图片作为背景
 * @param string 需要编码的字符串
 @param margin 二维码边界
 */
+(UIImage *)qrEncodeWithCircle:(UIImage *)avatarImage
                  qRString:(NSString *)string
                    margin:(int)margin
                    radius:(float)radius
                outPutSize:(float)imagSize
                   qRColor:(UIColor *)color{

    
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:color];
    int widthQR = 2*margin + [qr QRVersionForString:string withErrorLevel:QR_ECLEVEL_H withMode:0];
    int widthBackQR = 1.414*widthQR + 6;
    
    int sizeOfPix = floor(imagSize/widthBackQR);
    if (sizeOfPix%2 !=0) {
        sizeOfPix--;
    }
    if (sizeOfPix>=20) {
        sizeOfPix = 20;
    }
    
    int versionNormal =(ceilf)( (widthQR - 2*margin -21)/4.0) +1;
    int versionBig = (ceilf)((widthBackQR - 21)/4.0)+1;
    
    float bigImageSize = ((versionBig -1)*4+21)*sizeOfPix;
    float smallImageSize = widthQR * sizeOfPix;
    
    
    //        绘制QR背景图
    
    UIImage *QRBackImage = [qr qrImageForPixelString:string
                                        PixSize:sizeOfPix
                                              Margin:0
                                                Mode:versionBig
                                outPutSize:imagSize];
    
    //      绘制 真正的QR图
    
    UIImage *QRNormalImage = [qr qrImageForPixelString:string
                                               PixSize:sizeOfPix
                                            Margin:margin
                                                  Mode:versionNormal
                              outPutSize:imagSize];
  
    
    //       两张图片叠加（中间部分透明 然后将小图添加上去）
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //        float size = cirQRImage.size.width;
    #if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
        int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    #else
        int bitmapInfo = kCGImageAlphaPremultipliedLast;
    #endif
	CGContextRef ctx = CGBitmapContextCreate(0, bigImageSize, bigImageSize, 8, bigImageSize * 4, colorSpace, bitmapInfo);
    
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
//    CGContextFillPath(ctx);
    
    CGContextSetBlendMode(ctx,  kCGBlendModeNormal);
    CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    CGContextDrawImage(ctx, Rect,QRNormalImage.CGImage);
    
    CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
    
    QRBackImage = nil;
    QRNormalImage = nil;
    
    
    UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
    //        切圆
    CGImageRelease(qrCGImage);
    qrImage = [TRFilterGenerator createRoundedRectImage:qrImage size:qrImage.size radius:qrImage.size.width/2];

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
    
    CGImageRef backImageCGImage = CGBitmapContextCreateImage(ctx);
    
    UIImage *cirAvatarImage = [UIImage imageWithCGImage:backImageCGImage];
    
    CGImageRelease(backImageCGImage);
    // some releases
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
   
    //头像像素化
    cirAvatarImage =  [TRFilterGenerator CIPixellateWithImage:cirAvatarImage withInputScale:sizeOfPix];

    //头像圆角化
    cirAvatarImage = [self createRoundedRectImage:cirAvatarImage size:cirAvatarImage.size radius:cirAvatarImage.size.width/2];
    
    //滤镜合成
    
    cirAvatarImage =   [TRFilterGenerator CIDissolveTransitionWithImage:cirAvatarImage WithBackImage:qrImage];
    //压缩大小 并且设置背景为白色
    cirAvatarImage = [TRFilterGenerator imageWithImageSimple:cirAvatarImage backGroundColor:[UIColor whiteColor] newSize:CGSizeMake(imagSize, imagSize)];
                   //imageWithImageSimple:resultImage scaledToSize:CGSizeMake(imagSize, imagSize)];

    return cirAvatarImage;
   
    
}

/**
 * 第三类效果：模糊蒙版合成
 *
 */

+(UIImage *)qrEncodeWithGussianBlur:(UIImage *)inputImage
                   maskWithQRString:(NSString *)string
                             margin:(int)margin
                             radius:(float)radius
                               mode:(int)qrMode
                         outPutSize:(float)imagSize
                    monochromeColor:(UIColor *)color
               compositeWithTexture:(UIImage *)textureImage {
    
    CIImage *scrImage = [CIImage imageWithCGImage:[TRFilterGenerator imageWithImageSimple:inputImage backGroundColor:nil newSize:CGSizeMake(imagSize, imagSize)].CGImage];

    scrImage = [self ciImageWithGussianBlur:scrImage
                                    maskWithQRString:string
                                              margin:margin
                                              radius:radius
                                                mode:qrMode
                                          outPutSize:imagSize];
    
    CIImage *citexture = nil;
    if (textureImage) {
        citexture = [CIImage imageWithCGImage:[TRFilterGenerator imageWithImageSimple:textureImage backGroundColor:nil newSize:CGSizeMake(imagSize, imagSize)].CGImage];
    }
    
    scrImage = [self texturedImageWithCIImage:scrImage color:[CIColor colorWithCGColor:color.CGColor] textureImage:citexture];
    
    // Output UIImage
    return [self outputUIImageFromCIImage:scrImage rectangle:CGRectMake(0, 0, imagSize, imagSize)];
}


#pragma mark === Private Process : Output CIImage ====

/**
 * @brief 将两幅CIImage进行淡入淡出合成，以区分明度。
 * @param foregroundImage 前景图片
 * @param backgroundImage 背景图片
 */
+(UIImage *)CIDissolveTransitionWithImage:(UIImage *)inputImage WithBackImage:(UIImage *)targetImage{
    
    CIImage *forwardImage = [[CIImage alloc] initWithImage:inputImage];
    CIImage *inputBackImage = [[CIImage alloc] initWithImage:targetImage];
    
    CIFilter *  filter = [CIFilter filterWithName:@"CIDissolveTransition"];
    [filter setValue:forwardImage forKey:@"inputImage"];
    [filter setValue:inputBackImage forKey:@"inputTargetImage"];
    [filter setValue:[NSNumber numberWithFloat:0.65] forKey:@"inputTime"];
    CIImage *resultImage = filter.outputImage;
    
    UIImage *newImage = [self outputUIImageFromCIImage:resultImage rectangle:resultImage.extent];
    return newImage;
}

/**
 * @brief 将CIImage处理为高饱和的像素化艺术效果。
 * @param inputImage 输入图片
 * @param scale 像素大小
 */
+(UIImage *)CIPixellateWithImage:(UIImage *)inputImage withInputScale:(float)scale{
    
    CIContext *context = [TRContect sharedCiContextrManager];
    CIImage *forwardImage = [[CIImage alloc] initWithImage:inputImage];
    
    // Pixellate
    CIFilter *filter= [CIFilter filterWithName:@"CIPixellate"];
    CIVector *vector = [CIVector vectorWithX:inputImage.size.width/2.0f Y:inputImage.size.height /2.0f];
    [filter setDefaults];
    [filter setValue:vector forKey:@"inputCenter"];
    [filter setValue:[NSNumber numberWithDouble:scale] forKey:@"inputScale"];
    [filter setValue:forwardImage forKey:@"inputImage"];
    forwardImage = filter.outputImage;
    
    // Exposure Adjust
    CIFilter *exposureAdjustFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
    [exposureAdjustFilter setValue:forwardImage forKey:kCIInputImageKey];
    [exposureAdjustFilter setValue:@(0.0) forKey:kCIInputEVKey];
    forwardImage = [exposureAdjustFilter valueForKey:kCIOutputImageKey];
    
    // ColorControl
    CIFilter *colorControlFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlFilter setValue:forwardImage forKey:kCIInputImageKey];
    [colorControlFilter setValue:@(1.0) forKey:@"inputContrast"];
    [colorControlFilter setValue:@(0.00) forKey:@"inputBrightness"];
    [colorControlFilter setValue:@(12.0) forKey:@"inputSaturation"];
    forwardImage = colorControlFilter.outputImage;
    
    CGImageRef cgiimage = [context createCGImage:forwardImage fromRect:forwardImage.extent];
    
    UIImage *newImage = [UIImage imageWithCGImage:cgiimage scale:1.0f orientation:inputImage.imageOrientation];
    
    CGImageRef cr = CGImageCreateWithImageInRect([newImage CGImage], CGRectMake(0, 0, newImage.size.width-scale, newImage.size.height-scale));
    //    裁掉多余的一条边
	UIImage *croppedImage = [UIImage imageWithCGImage:cr];
    
    
    CGImageRelease(cr);
    CGImageRelease(cgiimage);
    return croppedImage;
    
}

/**
 * 将CIImage复制为两份，进行明度的差异化处理并通过一个蒙版图形合成。
 *
 */
+ (CIImage *)ciImageWithGussianBlur:(CIImage *)inputImage
                   maskWithQRString:(NSString *)string
                             margin:(int)margin
                             radius:(float)radius
                               mode:(int)qrMode
                         outPutSize:(float)imagSize {
    
    CIImage *scrImage = inputImage;
    
    // Affine Clamp the scrImage
    NSString *clampFilterName = @"CIAffineClamp";
    CIFilter *clamp = [CIFilter filterWithName:clampFilterName];
    [clamp setValue:scrImage forKey:kCIInputImageKey];
    CIImage *clampResult = [clamp valueForKey:kCIOutputImageKey];
    
    
    // Apply Gaussian Blur filter
    
    NSString *gaussianBlurFilterName = @"CIGaussianBlur";
    CIFilter *gaussianBlur           = [CIFilter filterWithName:gaussianBlurFilterName];
    [gaussianBlur setValue:clampResult
                    forKey:kCIInputImageKey];
    [gaussianBlur setValue:[NSNumber numberWithFloat:50.0]
                    forKey:@"inputRadius"];
    CIImage *gaussianBlurResult = [gaussianBlur valueForKey:kCIOutputImageKey];
    
    
    // Adjust Brightness of frontground
    
    CIFilter *lightcolorGenerateFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:kCIInputColorKey, [CIColor colorWithString:@"1 1 1 0.3"], nil];
    CIImage *lightColor = [lightcolorGenerateFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *bgblendFilter = [CIFilter filterWithName:@"CISourceAtopCompositing" keysAndValues:kCIInputImageKey, lightColor, kCIInputBackgroundImageKey, scrImage, nil];
    CIImage * background = [bgblendFilter valueForKey:kCIOutputImageKey];
    
    
    // Adjust Brightness of background
    
    CIFilter *darkcolorGenerateFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:kCIInputColorKey, [CIColor colorWithString:@"0 0 0 0.5"], nil];
    CIImage *darkColor = [darkcolorGenerateFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode" keysAndValues:kCIInputImageKey, gaussianBlurResult, kCIInputBackgroundImageKey, darkColor, nil];
    CIImage * frontground = [blendFilter valueForKey:kCIOutputImageKey];
    
    
    // Compose with Mask filter
    NSString *maskFilterName = @"CIBlendWithAlphaMask";
    CIFilter *mask = [CIFilter filterWithName:maskFilterName];
    
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:nil];
    
    CIVector *faceRectangle = [self faceRectangleVectorDetectedFromImage:inputImage];
    if (faceRectangle) {
        
        CGFloat clearRadius = MIN(imagSize * 0.18, faceRectangle.Z * 0.4);
        
        [qr setCLearRadius:clearRadius center:CGPointMake(faceRectangle.X, imagSize - faceRectangle.Y)];
    }
    
    CIImage *qrMask = [CIImage imageWithCGImage:[qr qrImageForString:string  Margin:2 Mode:qrMode OutputSize:imagSize].CGImage];
    
    [mask setValue:frontground forKey:kCIInputImageKey];
    [mask setValue:qrMask forKey:kCIInputMaskImageKey];
    [mask setValue:background forKey:kCIInputBackgroundImageKey];
    
    CIImage *finalResult = [mask valueForKey:kCIOutputImageKey];
    
    return finalResult;
}

/**
 * 将CIImage进行特征抽象，并输出为单色的版画效果。
 *
 */
+ (CIImage *)ciImagePrintmaikingWithImage:(CIImage *)inputImage color:(CIColor *)color needBrighten:(BOOL)needsBrighten {
    
    CIImage *resultImage = inputImage;
    
    CGFloat greyscale = [self greyscaleFromRGBColor:color];
    
    // False Color
    CIFilter *falseColorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [falseColorFilter setValue:resultImage forKey:kCIInputImageKey];
    [falseColorFilter setValue:color forKey:@"inputColor0"];
    resultImage = [falseColorFilter valueForKey:kCIOutputImageKey];
    
    // Exposure Adjust
    CIFilter *exposureAdjustFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
    [exposureAdjustFilter setValue:resultImage forKey:kCIInputImageKey];
    if (needsBrighten) {
        [exposureAdjustFilter setValue:@(1.4 - greyscale) forKey:kCIInputEVKey];
    } else {
        [exposureAdjustFilter setValue:@(1.6 - greyscale*1.5) forKey:kCIInputEVKey];
    }
    
    resultImage = [exposureAdjustFilter valueForKey:kCIOutputImageKey];

    // ColorControl
    CIFilter *colorControlFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlFilter setValue:resultImage forKey:kCIInputImageKey];
    [colorControlFilter setValue:@(1.95) forKey:@"inputContrast"];
    [colorControlFilter setValue:@(0.06) forKey:@"inputBrightness"];
    [colorControlFilter setValue:@(1.0) forKey:@"inputSaturation"];
    resultImage = [colorControlFilter valueForKey:kCIOutputImageKey];
    
    // Monochrome
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    [monochromeFilter setValue:resultImage forKey:kCIInputImageKey];
    [monochromeFilter setValue:[CIColor colorWithRed:0 green:0 blue:0] forKey:kCIInputColorKey];
    [monochromeFilter setValue:[NSNumber numberWithFloat:1] forKey:kCIInputIntensityKey];
    resultImage = [monochromeFilter valueForKey:kCIOutputImageKey];
    
    if (needsBrighten) {
        CIFilter *colorMatrixFilter = [CIFilter filterWithName:@"CIColorMatrix"];
        [colorMatrixFilter setValue:resultImage forKey:kCIInputImageKey];
        [colorMatrixFilter setValue:[CIVector vectorWithString:@"[1 0 0 0]"] forKey:@"inputRVector"];
        [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0 1 0 0]"] forKey:@"inputGVector"];
        [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0 0 1 0]"] forKey:@"inputBVector"];
        [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0 0 0 1]"] forKey:@"inputAVector"];
        [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0.35 0.35 0.35 0]"] forKey:@"inputBiasVector"];
        resultImage = [colorMatrixFilter valueForKey:kCIOutputImageKey];
        
        CIFilter *gammaFilter = [CIFilter filterWithName:@"CIGammaAdjust"];
        [gammaFilter setValue:resultImage forKey:kCIInputImageKey];
        [gammaFilter setValue:@0.90 forKey:@"inputPower"];
        resultImage = gammaFilter.outputImage;
    }
    
    return resultImage;
}

/**
 * 将CIImage处理为单色/两色的波普艺术效果，目前默认为波点
 *
 */
+ (CIImage *)popartImageWithCIImage:(CIImage *)inputImage color0:(CIColor *)color0 color1:(CIColor *)color1 {
    
    CIFilter *dotScreen = [CIFilter filterWithName:@"CIDotScreen"];
    [dotScreen setValue:inputImage forKey:kCIInputImageKey];
    [dotScreen setValue:[CIVector vectorWithX:0 Y:0] forKey:@"inputCenter"];
    [dotScreen setValue:@(6.0) forKey:@"inputWidth"];
    [dotScreen setValue:@(0.0) forKey:@"inputAngle"];
    [dotScreen setValue:@(0.7) forKey:@"inputSharpness"];
    CIImage *resultImage = [dotScreen valueForKey:kCIOutputImageKey];
    
    // False Color
    CIFilter *falseColorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [falseColorFilter setValue:resultImage forKey:kCIInputImageKey];
    [falseColorFilter setValue:color0 forKey:@"inputColor0"];
    if (color1) {
        [falseColorFilter setValue:color1 forKey:@"inputColor1"];
    }
    resultImage = [falseColorFilter valueForKey:kCIOutputImageKey];
    
    return resultImage;
}

/**
 * 为CIImage进行着色和纹理合成
 *
 */
+ (CIImage *)texturedImageWithCIImage:(CIImage *)inputImage color:(CIColor *)color textureImage:(CIImage *)textureImage {
    
    CIImage *scrImage = inputImage;
    
    // Monochromelize
    if (color) {
        NSString  *colorMonochromeFilterName = @"CIColorMonochrome";
        CIFilter *colorMonochrome =[CIFilter filterWithName:colorMonochromeFilterName];
        [colorMonochrome setValue:scrImage forKey:kCIInputImageKey];
        [colorMonochrome setValue:color forKey:kCIInputColorKey];
        [colorMonochrome setValue:[NSNumber numberWithFloat:1.0] forKey:kCIInputIntensityKey];
        scrImage = [colorMonochrome  valueForKey:kCIOutputImageKey];
    } else {
        // If no blend color designated, apply with some color controls.
//        NSString *colorControlFilterName = @"CIColorControls";
//        CIFilter *colorControl = [CIFilter filterWithName:colorControlFilterName];
//        [colorControl setValue:scrImage forKey:kCIInputImageKey];
//        [colorControl setValue:@(1.0) forKey:@"inputContrast"];
//        [colorControl setValue:@(1.0) forKey:@"inputSaturation"];
//        [colorControl setValue:@(0) forKey:@"inputBrightness"];
//        scrImage = [colorControl valueForKey:kCIOutputImageKey];
    }
    
    // Composite with texture
    if (textureImage) {
        CIFilter *affineTrans = [CIFilter filterWithName:@"CIAffineTile" keysAndValues:
                                 kCIInputImageKey, textureImage, nil];
        textureImage = [affineTrans valueForKey:kCIOutputImageKey];
        
        CIFilter *textureComposite = [CIFilter filterWithName:@"CIOverlayBlendMode" keysAndValues:
                                      kCIInputImageKey, scrImage,
                                      kCIInputBackgroundImageKey, textureImage, nil];
        scrImage = [textureComposite valueForKey:kCIOutputImageKey];
    }
    
    return scrImage;
}

+ (CIImage *)borderedImageWithImage:(CIImage *)inputImage outputSize:(CGFloat)imageSize inset:(CGFloat)inset color:(UIColor *)color {
    UIImage *borderImage = [self createBorderImageOfSize:CGSizeMake(imageSize, imageSize) inset:inset color:color];
    
    // Composite
    CIFilter *compositingFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [compositingFilter setValue:[CIImage imageWithCGImage:borderImage.CGImage] forKey:@"inputImage"];
    [compositingFilter setValue:inputImage forKey:@"inputBackgroundImage"];
    CIImage *compositedImage = compositingFilter.outputImage;
    
    return compositedImage;
}

#pragma mark ===图片压缩
//图片压缩
 
+(UIImage *)imageWithImageSimple:(UIImage *)image backGroundColor:(UIColor *)color newSize:(CGSize )newSize{
    
    UIGraphicsBeginImageContext(newSize);
    
    if (color) {

        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetFillColorWithColor(context, color.CGColor);
        
        CGContextFillRect(context, CGRectMake(0, 0, newSize.width,newSize.height));
    }
    
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;

}

#pragma mark === 面部识别 ===

+ (CIImage *)maskFromDetectedFaceInImage:(CIImage *)inputImage hollow:(BOOL)isHollow {
    
    CIVector *faceRectangle = [self faceRectangleVectorDetectedFromImage:inputImage];
    
    CIVector *center = [CIVector vectorWithX:faceRectangle.X Y:faceRectangle.Y];
    
    CIFilter *radialGredient = [CIFilter filterWithName:@"CIRadialGradient"];
    [radialGredient setValue:center forKey:kCIInputCenterKey];
    
    CIColor *hollowColor = [CIColor colorWithString:@"0 0 0 0"];
    CIColor *solidColor = [CIColor colorWithString:@"0 0 0 1"];
    
    [radialGredient setValue:isHollow ? solidColor : hollowColor forKey:@"inputColor0"];
    [radialGredient setValue:isHollow ? hollowColor : solidColor forKey:@"inputColor1"];
    [radialGredient setValue:@(inputImage.extent.size.width * 0.15) forKey:@"inputRadius0"];
    [radialGredient setValue:@(inputImage.extent.size.width * 0.18) forKey:@"inputRadius1"];
    
    CIImage *maskImage = [radialGredient valueForKey:kCIOutputImageKey];
    
    return maskImage;
}

+ (CIVector *)faceRectangleVectorDetectedFromImage:(CIImage *)inputImage {
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:nil];
    NSArray *faceArray = [detector featuresInImage:inputImage options:nil];
    
    if (!([faceArray count] > 0)) {
        return nil;
    }
    
    CIFaceFeature *face = faceArray[0];
    
    CGFloat xCenter = face.bounds.origin.x + face.bounds.size.width/2.0;
    CGFloat yCenter = face.bounds.origin.y + face.bounds.size.height/2.0;
    CGFloat w = face.bounds.size.width;
    CGFloat h = face.bounds.size.height;
    
//    if (face.hasLeftEyePosition && face.hasRightEyePosition) {
//        xCenter = (face.leftEyePosition.x + face.rightEyePosition.x) * 0.5;
//        yCenter = (face.leftEyePosition.y + face.rightEyePosition.y) * 0.5;
//        w = MAX(face.bounds.size.width, face.bounds.size.height);
//        h = MAX(face.bounds.size.width, face.bounds.size.height);
//    }
    
    CIVector *faceRectangle = [CIVector vectorWithX:xCenter Y:yCenter Z:w W:h];
    
    return faceRectangle;
}

+ (BOOL)configureQRGeneratorToReduceFace:(QRCodeGenerator *)qrGenerator inputImage:(CIImage *)scrImage outputSize:(CGFloat)imageSize {
    
    CIVector *faceRectangle = [self faceRectangleVectorDetectedFromImage:scrImage];
    
    if (faceRectangle) {
        CGFloat clearRadius = MIN(imageSize * 0.18, faceRectangle.Z * 0.6);
        [qrGenerator setCLearRadius:clearRadius center:CGPointMake(faceRectangle.X, imageSize - faceRectangle.Y)];
        return YES;
    }
    
    return NO;
}

#pragma mark ==== CGImage图片处理 ====
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
    int w = size.width;
    int h = size.height;
    UIImage *img = image;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context2 = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, 1);
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

+ (UIImage *)createBorderImageOfSize:(CGSize)size inset:(CGFloat)inset color:(UIColor *)color {
    int w = size.width;
    int h = size.height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context2 = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, 1);
    CGRect rect = CGRectMake(0, 0, w, h);
    CGRect insetRect = CGRectInset(rect, inset, inset);
    
    CGContextBeginPath(context2);
    CGContextSetFillColorWithColor(context2, color.CGColor);
    CGContextFillRect(context2, rect);
    CGContextSetFillColorWithColor(context2, [UIColor clearColor].CGColor);
    CGContextSetBlendMode(context2, kCGBlendModeClear);
    CGContextFillRect(context2, insetRect);
    CGImageRef resultImage = CGBitmapContextCreateImage(context2);
    UIImage *img = [UIImage imageWithCGImage:resultImage];
    
    CGContextRelease(context2);
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(resultImage);
    
    return img;
}

+ (UIImage *)outputUIImageFromCIImage:(CIImage *)ciImage rectangle:(CGRect)rect {
    
    if (!ciImage) {
        return nil;
    }
    
    CIContext *context = [TRContect sharedCiContextrManager];
    CGImageRef imageref = [context createCGImage:ciImage
                                        fromRect:rect];
    UIImage*  resultImage = [UIImage imageWithCGImage:imageref];
    CGImageRelease(imageref);
    
    return resultImage;
}

#pragma mark === 色值换算 ===
+ (CGFloat)greyscaleFromRGBColor:(CIColor *)rgbColor {

    CGFloat gamma = 1.8f;
    
    //Apple RGB [gamma=1.80]
    //Gray = (R^1.8 * 0.2446  + G^1.8  * 0.6720  + B^1.8  * 0.0833)^(1/1.8)
    CGFloat greyscale = pow((pow(rgbColor.red, gamma) * 0.2446
                             + pow(rgbColor.green, gamma) * 0.6720
                             + pow(rgbColor.blue, gamma)* 0.0833),
                            1/gamma);
    
    return greyscale;
    
}

+ (UIColor *)brightColorFromOrignalColor:(UIColor *)originalColor {
    
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    BOOL isCompatible = [originalColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
    
    if (isCompatible) {
        UIColor *brightColor = [UIColor colorWithHue:hue saturation:0.05f brightness:1.0f alpha:alpha];
        return brightColor;
    }
    
    return nil;
}

@end
