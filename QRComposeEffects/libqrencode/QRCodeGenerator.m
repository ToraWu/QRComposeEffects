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

#import "QRCodeGenerator.h"
#import "qrencode.h"
#import "TRFilterGenerator.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

static QRCodeGenerator *instance = nil;

@implementation QRCodeGenerator

-(id)initWithRadius :(float)radius withColor:(UIColor*)color{
    self = [super init];
    if (self) {
       QRRadius =  radius ;
        QRcolor = color;
        clearCenter = CGPointMake(0, 0);
        clearRadius = 0;
    }
    return self;

}
#pragma mark===公共方法 获取二维码图片
/**
 * @brief 公共方法返回一张二维码的图片。qrencode库 默认为最低等级 容错为最低L QRencodeMode 为QRMODE8
 * @param string 源字符串
 * @param size 二维码中每个色块的大小 16
 * @param marginXY 二维码距离画布边界
 * @param mode 二维码级别
 * @param outPutSize 输出图片的尺寸大小 如果为0的话，图片不做压缩，输出默认大小
 */

- (UIImage *)qrImageForString:(NSString *)string
                   withMargin:(float)marginXY
                    withMode :(int)mode
               withOutputSize:(float)outImagesize{
	if (![string length]) {
		return nil;
	}
	
	QRcode *code = QRcode_encodeString([string UTF8String], mode, QR_ECLEVEL_H, QR_MODE_8, 1);
	if (!code) {
		return nil;
	}
    
    
    
    
    int leverl = code->width;
    //每一个色块的大小 取偶数
    
    int sizeOfPix = (floor)(outImagesize/(leverl+2*marginXY));
    if (sizeOfPix%2!=0) {
            sizeOfPix --;
    }
    
    
    
    float  size =(code->width+2.0*marginXY)*sizeOfPix;
    //图片压缩，通过计算，转换圆心及半径
    
    if (clearRadius!=0) {
        clearCenter.x = clearCenter.x*sizeOfPix*code->width/outImagesize;
        clearCenter.y = clearCenter.y*sizeOfPix*code->width/outImagesize;
        clearRadius = clearRadius *sizeOfPix*code->width/outImagesize;
        
        code =  [self qrCustomizeArea:code sieOfpix:sizeOfPix margin:marginXY];
    }
    
	// create context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
 
#if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
    int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
#else
    int bitmapInfo = kCGImageAlphaPremultipliedLast;
#endif
		CGContextRef ctx = CGBitmapContextCreate(0, size, size, 8, size * 4, colorSpace, bitmapInfo);
	CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -size);
	CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
	CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));

    //    加入抗锯齿 特别慢
    CGContextSetAllowsAntialiasing(ctx, true);
    CGContextSetShouldAntialias(ctx, true);
	// draw QR on this context

    if (QRcolor == [UIColor blackColor]||QRcolor == nil) {
        QRcolor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    }
    
    
 
        [self drawliquidQRCode:code context:ctx size:sizeOfPix  withMargin:marginXY];
    
	// get image
	CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
	UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];

    qrImage = [TRFilterGenerator imageWithImageSimple:qrImage backGroundColor:nil newSize:CGSizeMake(outImagesize, outImagesize)];
    
	// some releases
	CGContextRelease(ctx);
	CGImageRelease(qrCGImage);
	CGColorSpaceRelease(colorSpace);
	QRcode_free(code);
	
	return qrImage;
}


- (UIImage *)qrImageForString:(NSString *)string
                  withPixSize:(float)sizeofpix
                   withMargin:(float)marginXY
                    withMode :(int)mode{


	if (![string length]) {
		return nil;
	}
	
	QRcode *code = QRcode_encodeString([string UTF8String], mode, QR_ECLEVEL_H, QR_MODE_8, 1);
	if (!code) {
		return nil;
	}
    
    float  size =(code->width+2.0*marginXY)*sizeofpix;
    

    
    
	// create context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    #if __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_6_1
        int bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    #else
        int bitmapInfo = kCGImageAlphaPremultipliedLast;
    #endif
	CGContextRef ctx = CGBitmapContextCreate(0, size, size, 8, size * 4, colorSpace, bitmapInfo);
	
	CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -size);
	CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
	CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
//    抗锯齿 特别慢
    
    CGContextSetAllowsAntialiasing(ctx, true);
    CGContextSetShouldAntialias(ctx, true);
    
	// draw QR on this context
    
    if (QRcolor == [UIColor blackColor]||QRcolor == nil) {
        QRcolor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    }
    
    
    
    [self drawliquidQRCode:code context:ctx size:sizeofpix  withMargin:marginXY];
    
	// get image
	CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
	UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
    
    
	// some releases
	CGContextRelease(ctx);
	CGImageRelease(qrCGImage);
	CGColorSpaceRelease(colorSpace);
	QRcode_free(code);
	
	return qrImage;
}

#pragma mark===公共方法 获取二维码版本
/**
 * @brief 公共方法返回二维码宽度，容错为最低L QRencodeMode 为QRMODE8，返回所需要编码的最低版本（eg:1,2,3....40）
 * @param string 源字符串
 * @param level 容错级别
 */
- (int)QRVersionForString:(NSString *)string withErrorLevel:(QRecLevel)level withMode:(int)mode{
    
    
	QRcode *code = QRcode_encodeString([string UTF8String], mode, level, QR_MODE_8, 1);
    int result;
    if (code) {
        result  = code->width;
    }else
        result = 0;
    QRcode_free(code);
    return result;
	   
}


#pragma mark ====内部绘制二维码方法

/**
 * @brief 内部方法将普通黑白二维码绘图
 * @param size 二维码长度=宽度=size
 * @param marginXY 二维码距离画布边界
 */

-(void)drawDefaultQRCode:(QRcode *)code context:(CGContextRef)ctx size:(CGFloat)size withMargin:(float)marginXY{
	unsigned char *data = 0;
	int width;
	data = code->data;
	width = code->width;
	float zoom = (double)size / (code->width + 2.0 * marginXY);
	CGRect rectDraw = CGRectMake(0, 0, zoom, zoom);
	
	// draw
	CGContextSetFillColor(ctx, CGColorGetComponents([UIColor blackColor].CGColor));
	for(int i = 0; i < width; ++i) {
		for(int j = 0; j < width; ++j) {
			if(*data & 1) {
				rectDraw.origin = CGPointMake((j + marginXY) * zoom,(i + marginXY) * zoom);
				CGContextAddRect(ctx, rectDraw);
			}
			++data;
		}
	}
	CGContextFillPath(ctx);
}

/**
 * @brief  二维码液化算法
 * @param size 二维码长度=宽度=size
 * @param marginXY 二维码距离画布边界
   @param rad   液化半径（0-1）
 */

- (void)drawliquidQRCode:(QRcode *)code context:(CGContextRef)ctx size:(CGFloat)size withMargin:(float)marginXY{
    
 
    
	unsigned char *data = 0;
	int width;
	data = code->data;
	width = code->width;
    
	float zoom = size;
//    ( (double)size / (code->width + 2.0 * marginXY));//每个色块的尺寸
    float radius = (floor)(QRRadius*zoom*0.5);
    
    double qr_startX = marginXY *zoom;
    double qr_startY = marginXY *zoom;
    // draw
    double byte_xpos = qr_startX ;
    double byte_ypos = qr_startY ;
    
    if (backGroundColor!=nil) {
        
    
    [self printQRbackGroundColor:ctx backcolor:backGroundColor Size:width*size];
    
    }
    
    
    
	for(int i = 0; i < width; i++) {//行数y
		for(int j = 0; j < width; j++) {//列数x
            
            BOOL topLeftRounded=false;
            BOOL topRightRounded=false;
            BOOL bottomRightRounded=false;
            BOOL bottomLeftRounded=false;
            
            unsigned int above,below,left,right,above_left,above_right,below_left,below_right;
            
            
            if (i==0) {
                above = 0;
            }else
                above = data[(i-1)*width+j]&1;
            if (i == width-1) {
                below = 0;
            }else
                below =data[(i+1)*width+j]&1;
            if (j == 0) {
                left = 0;
            }else
                left = data[i*width+j-1]&1;
            if (j ==width -1) {
                right = 0;
            }else
                right =data[(i)*width+j+1]&1;
            
            if (i==0 ||j==0) {
                above_left = 0;
            }else
                above_left =  data[(i-1)*width+j-1]&1;
            if (i==0 ||j==width -1) {
                above_right = 0;
            }else
                above_right = data[((i-1)*width+j+1)]&1;
            if (i ==width-1 || j==0) {
                below_left = 0;
            }else
                below_left =  data[(i+1)*width+j-1]&1;
            if (i==width-1 ||j==width-1) {
                below_right = 0;
            }else
                below_right = data[(i+1)*width+j+1]&1;
            
            
            //Figure out if this byte is ON or OFF
            if(data[i*width+j] & 1)
            {	//This one is on
                //Figure out upper left
                if( left == 0  && above == 0  )
                {
                    //There is nothing to above or to the left so this should be rounded
                    //
                    [self printOnUpperLeftR :ctx withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                    topLeftRounded=true;
                }else{
                    [self printOnNormal:ctx withX:byte_xpos withY:byte_ypos withSize:zoom];
                }
                
                //Figure out upper right
                if( right == 0  && above == 0  )
                {
                    //There is nothing to above or to the left so this should be rounded
                     [self printOnUpperRightR:ctx  withX:(byte_xpos+zoom/2) withY:byte_ypos withSize:zoom withRad:radius];
                    topRightRounded=true;
                }else{
        
                    [self printOnNormal:ctx withX:byte_xpos+zoom/2 withY:byte_ypos withSize:zoom];
                }
                
                //Figure out lower rigt
                if( right == 0  && below == 0  )
                {
                    //There is nothing to above or to the left so this should be rounded
                     [self printOnLowerRightR:ctx  withX:byte_xpos+zoom/2 withY:byte_ypos+zoom/2 withSize:zoom withRad:radius];
                    bottomRightRounded=true;
                }else{

                     [self printOnNormal:ctx  withX:byte_xpos+zoom/2 withY:byte_ypos+zoom/2 withSize:zoom];
                }
                
                //Figure out lower left
                
                if( left == 0  && below == 0  )
                {
                    //There is nothing to below or to the left so this should be rounded
                     [self printOnLowerLeftR:ctx  withX:byte_xpos withY:byte_ypos+zoom/2 withSize:zoom withRad:radius];
                    bottomLeftRounded=true;
                }else{

                     [self printOnNormal:ctx  withX:byte_xpos withY:byte_ypos+zoom/2 withSize:zoom];
                }
                
                
                if(topLeftRounded && topRightRounded && bottomRightRounded && bottomLeftRounded)
                {	//This is a solitary dot so lets color it differently to add interest

                    [self printOnRounded:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom];
                }
                
                
            }else
            {// This is an off.... throw in some rounded stuff
                
                
                if( left == 1  && above == 1  && above_left == 1)
                {
                    //There is nothing to above or to the left so this should be rounded
   
                    [self printOffUpperLeftR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    //Do nothing, this is supposed to be blank
                }
                
                //Figure out upper right
                if( right == 1  && above == 1 && above_right == 1 )
                {
                    //There is nothing to above or to the left so this should be rounded
 
                    
                     [self printOffUpperRightR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    
                }
                
                //Figure out lower rigt
                if( right == 1  && below == 1  && below_right == 1)
                {
                    //There is nothing to above or to the left so this should be rounded
 
                     [self printOffLowerRightR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    
                }
                //Figure out lower left
                if( left == 1  && below == 1  && below_left == 1)
                {
                    //There is nothing to below or to the left so this should be rounded

                    
                   [self printOffLowerLeftR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    
                }
                
            }

            byte_xpos += zoom;
            
		}
		byte_xpos = qr_startX;
        //
		byte_ypos +=zoom;
	}
    
    
}

- (void)printOnNormal:(CGContextRef)ctx withX:(double)x withY:(double)y withSize:(double)zoom {
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));
    
    CGContextAddRect(ctx, CGRectMake(x, y, zoom/2, zoom/2));
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
//    CGContextDrawPath(ctx, kCGPathFillStroke);

    
    
}
- (void)printOnRounded:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom {
    
    //xy 为圆心，zoom为椭圆的宽度与长度
    //black
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));
    
    CGContextAddEllipseInRect(ctx, CGRectMake(x, y, zoom, zoom));
    CGContextClosePath(ctx);
//    CGContextDrawPath(ctx, kCGPathFillStroke);
       CGContextFillPath(ctx);
    
    
    
}

- (void)printOnUpperLeftR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));
    
    CGContextAddRect(ctx, CGRectMake(x, y, zoom/2, zoom/2));
    CGContextClosePath(ctx);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx, x+radious, y);
    CGContextAddArcToPoint(ctx, x, y, x, y+radious, radious);
    CGContextAddLineToPoint(ctx, x,y);
    
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    
}
- (void)printOnUpperRightR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));

    CGContextAddRect(ctx, CGRectMake(x, y, zoom/2, zoom/2));
    CGContextClosePath(ctx);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx, x+(zoom/2-radious), y);
    CGContextAddArcToPoint(ctx, x+zoom/2, y, x+zoom/2, y+radious, radious);
    CGContextAddLineToPoint(ctx, x+zoom/2,y);
    
    CGContextClosePath(ctx);
    
    CGContextFillPath(ctx);
 
    
    
    
}
- (void)printOnLowerRightR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));

    CGContextAddRect(ctx, CGRectMake(x, y, zoom/2, zoom/2));
    CGContextClosePath(ctx);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx, x+zoom/2, y+(zoom/2-radious));
    CGContextAddArcToPoint(ctx, x+zoom/2, y+zoom/2, x+zoom/2-radious, y+zoom/2, radious);
    CGContextAddLineToPoint(ctx, x+zoom/2,y+zoom/2);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);


}
- (void)printOnLowerLeftR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious {
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));

    CGContextAddRect(ctx, CGRectMake(x, y, zoom/2, zoom/2));
    CGContextClosePath(ctx);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx, x, y+(zoom/2-radious));
    CGContextAddArcToPoint(ctx, x, y+zoom/2, x+radious, y+zoom/2, radious);
    CGContextAddLineToPoint(ctx, x,y+zoom/2);
    
    CGContextClosePath(ctx);
    
    CGContextFillPath(ctx);
    
    
}

- (void)printOffUpperLeftR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    float margin = 0;
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));

    CGContextFillRect(ctx, CGRectMake(x,y, radious-margin, radious-margin));
    
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx,x+radious, y+radious);
    CGContextAddArc(ctx, x+radious, y+radious,radious, DEGREES_TO_RADIANS(180),DEGREES_TO_RADIANS(270), 0);
    
    CGContextClosePath(ctx);
    CGContextDrawPath(ctx, kCGPathFillStroke);
    CGContextFillPath(ctx);
    
    
}
- (void)printOffUpperRightR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    float margin = 0;
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));
    
    CGContextFillRect(ctx, CGRectMake(x+zoom-radious+margin, y, radious-margin, radious-margin));
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx,x+zoom-radious, y+radious);
    CGContextAddArc(ctx, x+zoom-radious, y+radious,radious, DEGREES_TO_RADIANS(270),DEGREES_TO_RADIANS(0), 0);
 
    CGContextFillPath(ctx);
    
    }
- (void)printOffLowerRightR:(CGContextRef)ctx withX:(double)x withY:(double)y withSize:(double)zoom withRad:(float)radious{
    float margin = 0;
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));
    CGContextFillRect(ctx, CGRectMake(x+zoom-radious+margin, y+zoom-radious+margin, radious-margin, radious-margin));
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    CGContextMoveToPoint(ctx,x+zoom-radious, y+zoom-radious);
    CGContextAddArc(ctx, x+zoom-radious, y+zoom-radious,radious, DEGREES_TO_RADIANS(0),DEGREES_TO_RADIANS(90), 0);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
}
- (void)printOffLowerLeftR:(CGContextRef)ctx withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    float margin = 0;
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor colorWithRed:0 green:0 blue:0 alpha:0 ].CGColor));
    CGContextFillRect(ctx, CGRectMake(x-margin, y+zoom-radious+margin, radious-margin, radious-margin));
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    CGContextMoveToPoint(ctx,x+radious, y+zoom-radious);
    CGContextAddArc(ctx, x+ radious, y+zoom-radious,radious, DEGREES_TO_RADIANS(90),DEGREES_TO_RADIANS(180), 0);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    
    
}

-(void)printQRbackGroundColor:(CGContextRef)ctx backcolor:(UIColor *)backColor Size:(double)imageSize{

    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
    const CGFloat *components = CGColorGetComponents(backGroundColor.CGColor);
    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    
    CGContextAddRect(ctx, CGRectMake(0, 0,imageSize, imageSize));
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);

}

-(void)setQRBackGroundColor:(UIColor *)color{

    backGroundColor = color;
}


-(void)setCLearRadius:(float)radius center:(CGPoint)point{

    clearRadius = radius;
    clearCenter = point;
    
    
}

#pragma mark ====内部方法 计算是否再绘制区域
-(QRcode *) qrCustomizeArea:(QRcode *)code sieOfpix :(float)size margin:(float)marginxy{
    
    for(int i = 0;i<code->width;i++){
        for(int j = 0;j<code->width;j++){
    
            float x = j*size-size+marginxy*size;
            float y = i*size-size+marginxy*size;
            
            
            float dd = (x-clearCenter.x)*(x-clearCenter.x)+(y-clearCenter.y)*(y-clearCenter.y);
            float rr = clearRadius*clearRadius;
            
            if (dd<=rr) {
                    code->data[(i)*code->width+j]=0x0;
            }
        }
    }
    return code
    ;
    
}
@end
