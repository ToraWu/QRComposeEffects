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
@synthesize QRRadious;
@synthesize QRcolor;
+(QRCodeGenerator*)shareInstance
{
    @synchronized(self){
        if (!instance) {
            instance = [[QRCodeGenerator alloc]init];
        }
    }
    
    return instance;
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
                  withPixSize:(float)sizeOfPix
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
 
    float  size = (code->width+2.0*marginXY)*sizeOfPix;
    
	// create context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(0, size, size, 8, size * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	
	CGAffineTransform translateTransform = CGAffineTransformMakeTranslation(0, -size);
	CGAffineTransform scaleTransform = CGAffineTransformMakeScale(1, -1);
	CGContextConcatCTM(ctx, CGAffineTransformConcat(translateTransform, scaleTransform));
    
	// draw QR on this context
    
//    if (!QRcolor) {
    
        QRcolor = [UIColor blackColor];
//    }
   
//    CGColorSpaceRef colorSpace2 =CGColorGetColorSpace(QRcolor.CGColor);
//    NSLog(@"color space: %@", colorSpace2);
    
    
        [[QRCodeGenerator shareInstance] drawliquidQRCode:code context:ctx size:size  withMargin:marginXY];
    
	// get image
	CGImageRef qrCGImage = CGBitmapContextCreateImage(ctx);
	UIImage * qrImage = [UIImage imageWithCGImage:qrCGImage];
    
    if (outImagesize != 0) {//压缩
        qrImage = [TRFilterGenerator imageWithImageSimple:qrImage scaledToSize:CGSizeMake(outImagesize, outImagesize)];
    }
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
- (int)QRVersionForString:(NSString *)string withErrorLevel:(QRecLevel)level{
    
    
	QRcode *code = QRcode_encodeString([string UTF8String], 0, level, QR_MODE_8, 1);
	if (!code) {
		return 0;
	}else
        return code->width;
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
    
	float zoom =( (double)size / (code->width + 2.0 * marginXY));//每个色块的尺寸
    float radius = (floor)(QRRadious*zoom*0.5);
    
    double qr_startX = marginXY *zoom;
    double qr_startY = marginXY *zoom;
    // draw
    double byte_xpos = qr_startX ;
    double byte_ypos = qr_startY ;
    
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
                    [[QRCodeGenerator shareInstance] printOnUpperLeftR :ctx withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                    topLeftRounded=true;
                }else{
                    [[QRCodeGenerator shareInstance] printOnNormal:ctx withX:byte_xpos withY:byte_ypos withSize:zoom];
                }
                
                //Figure out upper right
                if( right == 0  && above == 0  )
                {
                    //There is nothing to above or to the left so this should be rounded
                     [[QRCodeGenerator shareInstance]printOnUpperRightR:ctx  withX:(byte_xpos+zoom/2) withY:byte_ypos withSize:zoom withRad:radius];
                    topRightRounded=true;
                }else{
        
                    [[QRCodeGenerator shareInstance]printOnNormal:ctx withX:byte_xpos+zoom/2 withY:byte_ypos withSize:zoom];
                }
                
                //Figure out lower rigt
                if( right == 0  && below == 0  )
                {
                    //There is nothing to above or to the left so this should be rounded
                     [[QRCodeGenerator shareInstance]printOnLowerRightR:ctx  withX:byte_xpos+zoom/2 withY:byte_ypos+zoom/2 withSize:zoom withRad:radius];
                    bottomRightRounded=true;
                }else{

                     [[QRCodeGenerator shareInstance] printOnNormal:ctx  withX:byte_xpos+zoom/2 withY:byte_ypos+zoom/2 withSize:zoom];
                }
                
                //Figure out lower left
                
                if( left == 0  && below == 0  )
                {
                    //There is nothing to below or to the left so this should be rounded
                     [[QRCodeGenerator shareInstance] printOnLowerLeftR:ctx  withX:byte_xpos withY:byte_ypos+zoom/2 withSize:zoom withRad:radius];
                    bottomLeftRounded=true;
                }else{

                     [[QRCodeGenerator shareInstance] printOnNormal:ctx  withX:byte_xpos withY:byte_ypos+zoom/2 withSize:zoom];
                }
                
                
                if(topLeftRounded && topRightRounded && bottomRightRounded && bottomLeftRounded)
                {	//This is a solitary dot so lets color it differently to add interest

                    [[QRCodeGenerator shareInstance] printOnRounded:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom];
                }
                
                
            }else
            {// This is an off.... throw in some rounded stuff
                
                
                if( left == 1  && above == 1  && above_left == 1)
                {
                    //There is nothing to above or to the left so this should be rounded
   
                    [[QRCodeGenerator shareInstance] printOffUpperLeftR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    //Do nothing, this is supposed to be blank
                }
                
                //Figure out upper right
                if( right == 1  && above == 1 && above_right == 1 )
                {
                    //There is nothing to above or to the left so this should be rounded
 
                    
                     [[QRCodeGenerator shareInstance] printOffUpperRightR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    
                }
                
                //Figure out lower rigt
                if( right == 1  && below == 1  && below_right == 1)
                {
                    //There is nothing to above or to the left so this should be rounded
 
                     [[QRCodeGenerator shareInstance] printOffLowerRightR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
                }else{
                    
                }
                //Figure out lower left
                if( left == 1  && below == 1  && below_left == 1)
                {
                    //There is nothing to below or to the left so this should be rounded

                    
                   [[QRCodeGenerator shareInstance] printOffLowerLeftR:ctx  withX:byte_xpos withY:byte_ypos withSize:zoom withRad:radius];
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
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    
    CGContextAddRect(ctx, CGRectMake(x, y, zoom/2, zoom/2));
    CGContextClosePath(ctx);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
     CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    
    
    
}
- (void)printOnRounded:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom {
    
    //xy 为圆心，zoom为椭圆的宽度与长度
    //black
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextAddEllipseInRect(ctx, CGRectMake(x, y, zoom, zoom));
    CGContextClosePath(ctx);
    
    //    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor whiteColor].CGColor));
    //    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor whiteColor].CGColor));
    CGContextDrawPath(ctx, kCGPathFillStroke);
    
    
    
}

- (void)printOnUpperLeftR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    //  CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    //
    //    CGContextMoveToPoint(ctx,x+zoom/2, y+zoom/2);
    //    CGContextAddArc(ctx, x+zoom/2, y+zoom/2,zoom/2, DEGREES_TO_RADIANS(180),DEGREES_TO_RADIANS(270), 0);
    //    CGContextClosePath(ctx);
    //
    ////    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor whiteColor].CGColor));
    ////    CGContextSetFillColor(ctx, CGColorGetComponents( [[UIColor whiteColor] CGColor]));
    //      CGContextDrawPath(ctx, kCGPathFillStroke);
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
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
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
    
      CGContextSetFillColor(ctx,CGColorGetComponents(QRcolor.CGColor) );
    
}
- (void)printOnUpperRightR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    /*
     CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
     CGContextMoveToPoint(ctx,x, y+zoom/2);
     CGContextAddArc(ctx, x, y+zoom/2,zoom/2, DEGREES_TO_RADIANS(270),DEGREES_TO_RADIANS(0), 0);
     CGContextClosePath(ctx);
     CGContextDrawPath(ctx, kCGPathFillStroke);
     */
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
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
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
     CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
 
      CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
    
    
    
}
- (void)printOnLowerRightR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    /*CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
     CGContextMoveToPoint(ctx,x, y);
     CGContextAddArc(ctx, x, y,zoom/2, DEGREES_TO_RADIANS(0),DEGREES_TO_RADIANS(90), 0);
     CGContextClosePath(ctx);
     CGContextDrawPath(ctx, kCGPathFillStroke);
     */
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
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
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
      CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
    
}
- (void)printOnLowerLeftR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious {
    
    /*
     CGContextMoveToPoint(ctx,x+zoom/2, y);
     CGContextAddArc(ctx, x+zoom/2, y,zoom/2, DEGREES_TO_RADIANS(90),DEGREES_TO_RADIANS(180), 0);
     
     CGContextClosePath(ctx);
     CGContextDrawPath(ctx, kCGPathFillStroke);*/
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
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
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
      CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
}

- (void)printOffUpperLeftR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    float margin = 0;
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
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
    
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
      CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
}
- (void)printOffUpperRightR:(CGContextRef)ctx  withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    
    float margin = 0;
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    
    CGContextFillRect(ctx, CGRectMake(x+zoom-radious+margin, y, radious-margin, radious-margin));
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextSetFillColor(ctx, CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextMoveToPoint(ctx,x+zoom-radious, y+radious);
    CGContextAddArc(ctx, x+zoom-radious, y+radious,radious, DEGREES_TO_RADIANS(270),DEGREES_TO_RADIANS(0), 0);
    //    CGContextClosePath(ctx);
    //    CGContextDrawPath(ctx, kCGPathFillStroke);
    CGContextFillPath(ctx);
    
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
      CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
    
}
- (void)printOffLowerRightR:(CGContextRef)ctx withX:(double)x withY:(double)y withSize:(double)zoom withRad:(float)radious{
    float margin = 0;
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextFillRect(ctx, CGRectMake(x+zoom-radious+margin, y+zoom-radious+margin, radious-margin, radious-margin));
    
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    CGContextMoveToPoint(ctx,x+zoom-radious, y+zoom-radious);
    CGContextAddArc(ctx, x+zoom-radious, y+zoom-radious,radious, DEGREES_TO_RADIANS(0),DEGREES_TO_RADIANS(90), 0);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
      CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
    
}
- (void)printOffLowerLeftR:(CGContextRef)ctx withX:(double)x withY:(double)y  withSize:(double)zoom withRad:(float)radious{
    float margin = 0;
    CGContextSetStrokeColor(ctx,CGColorGetComponents([UIColor clearColor].CGColor));
    CGContextFillRect(ctx, CGRectMake(x-margin, y+zoom-radious+margin, radious-margin, radious-margin));
    
    int blendMode = kCGBlendModeClear;
    CGContextSetBlendMode(ctx, (CGBlendMode) blendMode);
    CGContextMoveToPoint(ctx,x+radious, y+zoom-radious);
    CGContextAddArc(ctx, x+ radious, y+zoom-radious,radious, DEGREES_TO_RADIANS(90),DEGREES_TO_RADIANS(180), 0);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    
    CGContextSetBlendMode(ctx, kCGBlendModeNormal);
    
//    CGContextSetStrokeColor(ctx,CGColorGetComponents(QRcolor.CGColor));
    const CGFloat *components = CGColorGetComponents(QRcolor.CGColor);
//    CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], 1.0);
    CGContextSetStrokeColorWithColor(ctx, QRcolor.CGColor);
    CGContextSetFillColor(ctx, CGColorGetComponents(QRcolor.CGColor));
    
}





@end
