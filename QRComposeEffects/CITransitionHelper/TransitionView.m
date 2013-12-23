//
//  TransitionView.m
//  CITransitionSample
//
//  Created by shuichi on 13/03/10.
//  Copyright (c) 2013年 Shuichi Tsutsumi. All rights reserved.
//

#import "TransitionView.h"
#import "CITransitionHelper.h"


@interface TransitionView () <GLKViewDelegate>
{
    NSTimeInterval  base;
    CGRect _imageRect;
    CGRect _canvasRect;
    UIImage *_image;
    CIImage *_bgCIImage;
}
@property (nonatomic, strong) CIImage *image1;
@property (nonatomic, strong) CIImage *image2;
@property (nonatomic, strong) CIImage *maskImage;
@property (nonatomic, strong) CIVector *extent;
@property (nonatomic, strong) CIFilter *transition;
@property (nonatomic, strong) CIContext *myContext;
@property (nonatomic, strong) CADisplayLink *displayLink;
@end


@implementation TransitionView

- (void)awakeFromNib {

    // 遷移前後の画像とマスク画像を生成
//    UIImage *uiMaskImage = [UIImage imageNamed:@"mask.jpg"];
//    self.maskImage = [[CIImage alloc] initWithCGImage:uiMaskImage.CGImage];
    
    _bgCIImage = [[CIFilter filterWithName:@"CIConstantColorGenerator" keysAndValues:kCIInputColorKey, [CIColor colorWithString:@"1 1 1 1"], nil] valueForKey:kCIOutputImageKey];
    
    CGFloat screenScale = [UIScreen mainScreen].scale;
    
    _canvasRect = CGRectApplyAffineTransform(self.bounds, CGAffineTransformMakeScale(screenScale, screenScale));
    
    // 表示領域を示す矩形（CGRect型）
    _imageRect = CGRectZero;

    // 遷移アニメーションが起こる領域を示す矩形（CIVector型）
    self.extent = [CIVector vectorWithX:0
                                      Y:0
                                      Z:0
                                      W:0];
    
    // 遷移アニメーション制御の基準となる時刻
    base = [NSDate timeIntervalSinceReferenceDate];    

    // 遷移アニメーションを制御するタイマー
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    self.displayLink.frameInterval = 2.0;
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

    // EAGLDelegateの設定
    self.delegate = self;
    
    // コンテキスト生成
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.myContext = [CIContext contextWithEAGLContext:self.context];
    srandom((unsigned)time(NULL)<<2);
}

- (void)setImage:(UIImage *)image {
    self.image1   = [CIImage imageWithCGImage:_image.CGImage];
    self.image2   = [CIImage imageWithCGImage:image.CGImage];
    
    // 表示領域を示す矩形（CGRect型）
    _imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    // 遷移アニメーションが起こる領域を示す矩形（CIVector型）
    self.extent = [CIVector vectorWithX:0
                                      Y:0
                                      Z:image.size.width
                                      W:image.size.height];
    [self changeTransition:4];
    _image = image;
    // 遷移アニメーション制御の基準となる時刻
    base = [NSDate timeIntervalSinceReferenceDate];
}

- (UIImage *)image {
    return _image;
}


#pragma mark -------------------------------------------------------------------
#pragma mark Private

- (CIImage *)imageForTransitionAtTime:(float)time
{
    if (!self.image1) {
        return self.image2;
    }
    
    // 遷移前後の画像をtimeによって切り替える
    if (time < 1.0f)
    {
        [self.transition setValue:self.image1 forKey:@"inputImage"];
        [self.transition setValue:self.image2 forKey:@"inputTargetImage"];
    }
    else
    {
        return self.image2;
    }
    
    // 遷移アニメーションの時間を指定
    CGFloat transitionTime = 0.5 * (1 - cos(fmodf(time, 1.0f) * M_PI));
    
    [self.transition setValue:@(transitionTime) forKey:@"inputTime"];
    
    // フィルタ処理実行
    CIImage *transitionImage = [self.transition valueForKey:@"outputImage"];
    
    return transitionImage;
}


#pragma mark -------------------------------------------------------------------
#pragma mark Public

- (void)changeTransition:(NSUInteger)transitionIndex {
    
    switch (transitionIndex) {
            
        case 0:
        default:
            self.transition = [CITransitionHelper transitionWithType:kCITransitionTypeDissolve
                                                              extent:self.extent];
            break;
            
        case 1:
            self.transition = [CITransitionHelper transitionWithType:kCITransitionTypeCopyMachine
                                                              extent:self.extent];
            break;
            
        case 2:
            self.transition = [CITransitionHelper transitionWithType:kCITransitionTypeFlash
                                                              extent:self.extent];
            break;
            
        case 3:
            self.transition = [CITransitionHelper transitionWithType:kCITransitionTypeMod
                                                              extent:self.extent];
            break;
            
        case 4:
            self.transition = [CITransitionHelper transitionWithType:kCITransitionTypeSwipe
                                                              extent:self.extent];
            break;
            
        case 5:
            self.transition = [CITransitionHelper transitionWithType:kCITransitionTypeDisintegrateWithMask
                                                              extent:self.extent
                                                         optionImage:self.maskImage];
            break;
    }
}

- (NSString *)currentFilterName {
    
    return self.transition.name;
}


#pragma mark -------------------------------------------------------------------
#pragma mark GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // 遷移前後の画像をtimeによって切り替える
        float t = ([NSDate timeIntervalSinceReferenceDate] - base);
        
        CIImage *image = [self imageForTransitionAtTime:t];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            glClearColor(1, 1, 1, 1);
            glClear(GL_COLOR_BUFFER_BIT);
            
            [self.myContext drawImage:image
                               inRect:_canvasRect
                             fromRect:_imageRect];
        });
    });
}


#pragma mark -------------------------------------------------------------------
#pragma mark Timer Handler

- (void)onTimer:(NSTimer *)timer {

    [self setNeedsDisplay];
}

- (void)render:(CADisplayLink *)displayLink {
    [self setNeedsDisplay];
}


@end
