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
//        ciContextSingleton = [CIContext contextWithOptions:nil];
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
    
    
    [filter setValue:[NSNumber numberWithFloat:0.75] forKey:@"inputTime"];
    
    
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
    
    
    CGImageRelease(cr);
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
                              qRString:(NSString *)string
                                margin:(int)margin
                                  mode:(int)mode
                               radius :(float)radius
                            outPutSize:(float)imagSize
                               qRColor:(UIColor*)color
{
    
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:color];
    int leverl = [qr QRVersionForString:string withErrorLevel:QR_ECLEVEL_H withMode:mode];
    
    int sizeOfPix = (floor)(imagSize/(leverl+2*margin));
    if (sizeOfPix%2!=0) {
        sizeOfPix --;
    }
    //生成二维码 不压缩
   // UIImage *qrImage =  [qr qrImageForString:string withMargin:margin withMode:mode withOutputSize:imagSize];
    UIImage *qrImage = [qr qrImageForString:string withPixSize:sizeOfPix withMargin:margin withMode:mode];
    
    UIImage *newAvtarImage = [TRFilterGenerator imageWithImageSimple:avatarImage backGroundColor:nil newSize:qrImage.size];
                              //imageWithImageSimple:avatarImage scaledToSize:(qrImage.size)];
    
    //像素化 并裁掉了多余的一个边
    newAvtarImage =  [TRFilterGenerator CIPixellateWithImage:newAvtarImage withInputScale:(sizeOfPix)];

//    滤镜合成
    UIImage *newImage = [self CIDissolveTransitionWithImage:newAvtarImage WithBackImage:qrImage];
   
    newImage = [TRFilterGenerator imageWithImageSimple:newImage backGroundColor:[UIColor whiteColor] newSize:CGSizeMake(imagSize, imagSize)];
                //imageWithImageSimple:newImage scaledToSize:CGSizeMake(imagSize, imagSize)];
    return newImage;
    
}




#pragma mark === 第二种二维码效果 圆形二维码类似微信的效果
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
    
    UIImage *QRBackImage = [qr qrImageForString:string withPixSize:sizeOfPix withMargin:0 withMode:versionBig];

    
    //      绘制 真正的QR图
    UIImage *QRNormalImage = [qr qrImageForString:string withPixSize:sizeOfPix withMargin:margin withMode:versionNormal ];
  
    
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
    
    CIImage *citexture = [CIImage imageWithCGImage:[TRFilterGenerator imageWithImageSimple:textureImage backGroundColor:nil newSize:CGSizeMake(imagSize, imagSize)].CGImage];
    
    scrImage = [self texturedImageWithCIImage:scrImage color:[CIColor colorWithCGColor:color.CGColor] textureImage:citexture];
    
    // Output UIImage
    return [self outputUIImageFromCIImage:scrImage rectangle:CGRectMake(0, 0, imagSize, imagSize)];
}

+ (UIImage *)printmakingWithImage:(UIImage *)inputImage
                 maskWithQRString:(NSString *)string
                           margin:(int)margin
                           radius:(float)radius
                             mode:(int)qrMode
                       outPutSize:(float)imagSize
                           color0:(UIColor *)color0
                           color1:(UIColor *)color1
                       detectFace:(BOOL)detectFace {
    
    CIImage *scrImage = [CIImage imageWithCGImage:[TRFilterGenerator imageWithImageSimple:inputImage backGroundColor:nil newSize:CGSizeMake(inputImage.size.width, inputImage.size.height)].CGImage];
    
    CIImage *printmakingResult = [self ciImagePrintmaikingWithImage:scrImage color:[CIColor colorWithCGColor:color0.CGColor]];
    
    // Generate QRcode image
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:color0];
    
    CIImage *qrImage = [CIImage imageWithCGImage:[qr qrImageForString:string  withMargin:2 withMode:qrMode withOutputSize:imagSize].CGImage];
    
    CIImage *facemask = nil;
    if (detectFace) {
        facemask = [self maskFromDetectedFaceInImage:[CIImage imageWithCGImage:inputImage.CGImage] hollow:YES];
    }
    // Mask qr image with face
    if (facemask) {
 
        // Face regonised, reduce a circle around the face from qr.
        CIFilter *filter = [CIFilter filterWithName:@"CISourceOutCompositing"];
        [filter setValue:qrImage forKey:@"inputImage"];
        [filter setValue:facemask forKey:@"inputBackgroundImage"];
        qrImage = [filter valueForKey:kCIOutputImageKey];
        
    } else {
        
        // No face detected, scale the image into a square on the center of qr code.
        CIFilter *transformFilter = [CIFilter filterWithName:@"CIPerspectiveTransform"];
        [transformFilter setValue:printmakingResult forKey:kCIInputImageKey];
        CGFloat scaleFactor = 16.0f/43.0f;
        CGFloat originX = imagSize * (1-scaleFactor) * 0.5;
        CGFloat originY = imagSize * (1-scaleFactor) * 0.5;
        CGFloat width = imagSize * scaleFactor;
        CGFloat height = imagSize * scaleFactor;
        [transformFilter setValue:[CIVector vectorWithX:originX Y:originY] forKey:@"inputBottomLeft"];
        [transformFilter setValue:[CIVector vectorWithX:originX + width Y:originY] forKey:@"inputBottomRight"];
        [transformFilter setValue:[CIVector vectorWithX:originX + width Y:originY + height] forKey:@"inputTopRight"];
        [transformFilter setValue:[CIVector vectorWithX:originX Y:originY + height] forKey:@"inputTopLeft"];
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
    }
    
    // Composite
    CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [filter setValue:qrImage forKey:@"inputImage"];
    [filter setValue:printmakingResult forKey:@"inputBackgroundImage"];
    
    CIImage *compositedImage = [filter valueForKey:kCIOutputImageKey];

    // Popart filter
    compositedImage = [self popartImageWithCIImage:compositedImage color0:[CIColor colorWithCGColor:color0.CGColor] color1:color1 ? [CIColor colorWithCGColor:color1.CGColor] : nil];
    
    // Output UIImage
    return [self outputUIImageFromCIImage:compositedImage rectangle:CGRectMake(0, 0, imagSize, imagSize)];
}


#pragma mark === Private Generator : Output CIImage ====

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
    
    CIFilter *darkcolorGenerateFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:kCIInputColorKey, [CIColor colorWithString:@"0 0 0 0.5"], nil];
    CIImage *darkColor = [darkcolorGenerateFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIMultiplyBlendMode" keysAndValues:kCIInputImageKey, scrImage, kCIInputBackgroundImageKey, darkColor, nil];
    CIImage *frontground = [blendFilter valueForKey:kCIOutputImageKey];
    
    // Adjust Brightness of background
    
    CIFilter *lightcolorGenerateFilter = [CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:kCIInputColorKey, [CIColor colorWithString:@"1 1 1 0.5"], nil];
    CIImage *lightColor = [lightcolorGenerateFilter valueForKey:kCIOutputImageKey];
    
    CIFilter *bgblendFilter = [CIFilter filterWithName:@"CISourceAtopCompositing" keysAndValues:kCIInputImageKey, lightColor, kCIInputBackgroundImageKey, gaussianBlurResult, nil];
    CIImage *background = [bgblendFilter valueForKey:kCIOutputImageKey];
    
    
    // Compose with Mask filter
    NSString *maskFilterName = @"CIBlendWithAlphaMask";
    CIFilter *mask = [CIFilter filterWithName:maskFilterName];
    
    QRCodeGenerator *qr = [[QRCodeGenerator alloc] initWithRadius:radius withColor:nil];
    CIImage *qrMask = [CIImage imageWithCGImage:[qr qrImageForString:string  withMargin:2 withMode:qrMode withOutputSize:imagSize].CGImage];
    
    // Mask qr image with face
    CIImage *facemask = [self maskFromDetectedFaceInImage:inputImage hollow:YES];
    if (facemask) {
        CIFilter *filter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [filter setValue:qrMask forKey:@"inputImage"];
        [filter setValue:facemask forKey:@"inputBackgroundImage"];
        qrMask = [filter valueForKey:kCIOutputImageKey];
    }

    
    [mask setValue:frontground forKey:kCIInputImageKey];
    [mask setValue:qrMask forKey:kCIInputMaskImageKey];
    [mask setValue:background forKey:kCIInputBackgroundImageKey];
    
    CIImage *finalResult = [mask valueForKey:kCIOutputImageKey];
    
    return finalResult;
}

+ (CIImage *)ciImagePrintmaikingWithImage:(CIImage *)inputImage color:(CIColor *)color {
    
    CIImage *resultImage = inputImage;
    
//    CIFilter *highlightShadowAdjustFilter = [CIFilter filterWithName:@"CIHighlightShadowAdjust"];
//    [highlightShadowAdjustFilter setValue:resultImage forKey:kCIInputImageKey];
//    [highlightShadowAdjustFilter setValue:@(1.0) forKey:@"inputHighlightAmount"];
//    [highlightShadowAdjustFilter setValue:@(1.0) forKey:@"inputShadowAmount"];
//    resultImage = [highlightShadowAdjustFilter valueForKey:kCIOutputImageKey];
    
    // False Color
    CIFilter *falseColorFilter = [CIFilter filterWithName:@"CIFalseColor"];
    [falseColorFilter setValue:resultImage forKey:kCIInputImageKey];
    [falseColorFilter setValue:color forKey:@"inputColor0"];
    resultImage = [falseColorFilter valueForKey:kCIOutputImageKey];
    
    // Exposure Adjust
    CIFilter *exposureAdjustFilter = [CIFilter filterWithName:@"CIExposureAdjust"];
    [exposureAdjustFilter setValue:resultImage forKey:kCIInputImageKey];
    [exposureAdjustFilter setValue:@(1.24) forKey:kCIInputEVKey];
    resultImage = [exposureAdjustFilter valueForKey:kCIOutputImageKey];

    // ColorControl
    CIFilter *colorControlFilter = [CIFilter filterWithName:@"CIColorControls"];
    [colorControlFilter setValue:resultImage forKey:kCIInputImageKey];
    [colorControlFilter setValue:@(1.95) forKey:kCIInputContrastKey];
    [colorControlFilter setValue:@(0.06) forKey:kCIInputBrightnessKey];
    [colorControlFilter setValue:@(1.0) forKey:kCIInputSaturationKey];
    resultImage = [colorControlFilter valueForKey:kCIOutputImageKey];
    
    // Monochrome
    CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
    [monochromeFilter setValue:resultImage forKey:kCIInputImageKey];
    [monochromeFilter setValue:color forKey:kCIInputColorKey];
    [monochromeFilter setValue:[NSNumber numberWithFloat:1] forKey:kCIInputIntensityKey];
    resultImage = [monochromeFilter valueForKey:kCIOutputImageKey];
    
    // Apply Posterlize
//    CIFilter *posterlize = [CIFilter filterWithName:@"CIColorPosterize" keysAndValues:kCIInputImageKey, resultImage, @"inputLevels", @(20.0), nil];
//    resultImage = [posterlize valueForKey:kCIOutputImageKey];
    
    CIFilter *colorMatrixFilter = [CIFilter filterWithName:@"CIColorMatrix"];
    [colorMatrixFilter setValue:resultImage forKey:kCIInputImageKey];
    [colorMatrixFilter setValue:[CIVector vectorWithString:@"[1 0 0 0]"] forKey:@"inputRVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0 1 0 0]"] forKey:@"inputGVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0 0 1 0]"] forKey:@"inputBVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0 0 0 1]"] forKey:@"inputAVector"];
    [colorMatrixFilter setValue:[CIVector vectorWithString:@"[0.35 0.35 0.35 0]"] forKey:@"inputBiasVector"];
    resultImage = [colorMatrixFilter valueForKey:kCIOutputImageKey];
    
    return resultImage;
}

+ (CIImage *)maskFromDetectedFaceInImage:(CIImage *)inputImage hollow:(BOOL)isHollow {
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                            context:nil
                                            options:nil];
    NSArray *faceArray = [detector featuresInImage:inputImage options:nil];
    
    if (!([faceArray count] > 0)) {
        return nil;
    }
    
    CIFeature *face = faceArray[0];
    CGFloat xCenter = face.bounds.origin.x + face.bounds.size.width/2.0;
    CGFloat yCenter = face.bounds.origin.y + face.bounds.size.height/2.0;
    CIVector *center = [CIVector vectorWithX:xCenter Y:yCenter];
    
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

+ (CIImage *)popartImageWithCIImage:(CIImage *)inputImage color0:(CIColor *)color0 color1:(CIColor *)color1 {
    
    CIFilter *dotScreen = [CIFilter filterWithName:@"CIDotScreen"];
    [dotScreen setValue:inputImage forKey:kCIInputImageKey];
    [dotScreen setValue:[CIVector vectorWithX:0 Y:0] forKey:@"inputCenter"];
    [dotScreen setValue:@(8.0) forKey:@"inputWidth"];
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
        
        // Composite with texture
        if (textureImage) {
            CIFilter *affineTrans = [CIFilter filterWithName:@"CIAffineTile" keysAndValues:
                                     kCIInputImageKey, textureImage, nil];
            textureImage = [affineTrans valueForKey:kCIOutputImageKey];
            
            CIFilter *textureComposite = [CIFilter filterWithName:@"CIMultiplyCompositing" keysAndValues:
                                          kCIInputImageKey, scrImage,
                                          kCIInputBackgroundImageKey, textureImage, nil];
            scrImage = [textureComposite valueForKey:kCIOutputImageKey];
        }
    } else {
        // If no blend color designated, apply with some color controls.
        NSString *colorControlFilterName = @"CIColorControls";
        CIFilter *colorControl = [CIFilter filterWithName:colorControlFilterName];
        [colorControl setValue:scrImage forKey:kCIInputImageKey];
        [colorControl setValue:@(1.05) forKey:kCIInputContrastKey];
        [colorControl setValue:@(1.1) forKey:kCIInputSaturationKey];
        scrImage = [colorControl valueForKey:kCIOutputImageKey];
    }
    
    return scrImage;
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

@end
