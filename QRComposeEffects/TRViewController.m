//
//  TRViewController.m
//  QRComposeEffects
//
//  Created by Tora on 13-11-27.
//  Copyright (c) 2013年 Tora Wu. All rights reserved.
//

#import "TRViewController.h"
#import <CoreImage/CoreImage.h>
#import "TRFilterGenerator.h"
#import "QRCodeGenerator.h"
#import "TransitionView.h"



@interface TRViewController () {
    UIImage *_qrImage;
}

@property (nonatomic, strong) IBOutlet TransitionView *resultView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIView *boardView;

@property (nonatomic, readonly) UIImage *qrImage;
@property (nonatomic, strong) UIImage *userImage;
@property (nonatomic, strong) NSMutableDictionary *resultImageDict;
@property (nonatomic, copy) NSString *qrString;
@property (nonatomic, assign) int preferredQrLevel;
@property (nonatomic, copy) UIColor *customedColor0;
@property (nonatomic, copy) UIColor *customedColor1;

@property (nonatomic, strong) CIContext *ciContext;

@end

static NSArray *effectNameKeys;

@implementation TRViewController

#pragma mark ==== Life Cycle ====
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Init required objects
    EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.ciContext  = [CIContext contextWithEAGLContext:myEAGLContext options:nil];
    
    if (!effectNameKeys) {
        effectNameKeys = @[@"Popart Portrait",@"Printmaking",@"Pixellate", @"Circum"];
    }
    self.resultImageDict = [NSMutableDictionary new];
    self.pageControl.numberOfPages = [effectNameKeys count];
    
    // Sample data
    self.preferredQrLevel = 6;
    self.qrString = @"http://roundqr.sinaapp.com/index.php";
    self.userImage = [UIImage imageNamed:@"CIMG0285.JPG"];
    self.customedColor0 = [UIColor colorWithRed:0.7 green:0 blue:0.07 alpha:1];
    
    // Motion Effects
    self.boardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.boardView.layer.shadowOffset = CGSizeMake(0,2);
    self.boardView.layer.shadowOpacity = 0.5;
    self.boardView.layer.shadowRadius = 10;
    [self registerEffectForView:self.boardView depth:-10];
    [self registerShadowEffectForView:self.boardView depth:4*self.boardView.layer.shadowRadius];
    
    
//    self.resultView.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.resultView.layer.shadowOffset = CGSizeMake(0,-2);
//    self.resultView.layer.shadowOpacity = 0.5;
//    self.resultView.layer.shadowRadius = 5;
//    [self registerEffectForView:self.resultView depth:5];
//    [self registerShadowEffectForView:self.resultView depth:-4*self.resultView.layer.shadowRadius];
    
    
    //For test
    //self.pageControl.currentPage = self.pageControl.numberOfPages-1;
    self.pageControl.currentPage = 0;
    
    [self updateUI];
    
    //    test
    
    /*
    UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [self.navigationController.navigationBar addGestureRecognizer:gesture];
    [gesture setMinimumPressDuration:1.0f];
    [gesture setAllowableMovement:50.0];
    
    [self.navigationController.navigationBar addGestureRecognizer:gesture];
     */
    
    
}

/*
- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    
    if( gesture.state == UIGestureRecognizerStateBegan &&[gesture isKindOfClass:[UILongPressGestureRecognizer class]])
    {
        
//        扫描二维码部分：
//         导入ZBarSDK文件并引入一下框架
//         AVFoundation.framework
//         CoreMedia.framework
//         CoreVideo.framework
//         QuartzCore.framework
//         libiconv.dylib
//         引入头文件#import “ZBarSDK.h” 即可使用
        ZBarReaderViewController *reader = [ZBarReaderViewController new];
        reader.readerDelegate = self;
        reader.videoQuality= UIImagePickerControllerQualityTypeHigh;
        reader.supportedOrientationsMask = ZBarOrientationMaskAll;
//        reader.showsZBarControls = NO;
//        reader.tracksSymbols = NO;
        reader.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        
        reader.showsHelpOnFail = NO;
        //    reader.showsCameraControls = YES;
        ZBarImageScanner *scanner = reader.scanner;
        
        [self setOverlayPickerView:reader];
        
        
        [scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
        
        [self presentViewController:reader animated:YES completion:^{
            NSLog(@"跳转成功");
        }];
    }
    
    
#pragma mark ===自定义解码界面  或者使用ios 7 解码
    自定义扫描
     // Do any additional setup after loading the view.
//     ZBarImageScanner * scanner = [ZBarImageScanner new];
//     [scanner setSymbology: ZBAR_I25
//     config: ZBAR_CFG_ENABLE
//     to: 0];
//     readView = [[ZBarReaderView alloc] initWithImageScanner:scanner];
//     
//     
//     readView.readerDelegate = self;
//     
//     readView.frame = self.view.frame;
//     
//     [self.view addSubview:readView];
//     [self.view bringSubviewToFront:readView];
//     readView.showsFPS = YES;
//     readView.scanCrop = CGRectMake(0, 0, 1, 1);
//     [readView start];
 
 
}

- (void)setOverlayPickerView:(ZBarReaderViewController *)reader

{
    
    //清除原有控件
    
    for (UIView *temp in [reader.view subviews]) {
        
        for (UIButton *button in [temp subviews]) {
            
            if ([button isKindOfClass:[UIButton class]]) {
                
                [button removeFromSuperview];
                
            }
            
        }
        
        for (UIToolbar *toolbar in [temp subviews]) {
            
            if ([toolbar isKindOfClass:[UIToolbar class]]) {
                
                [toolbar setHidden:YES];
                
                [toolbar removeFromSuperview];
                
            }
            
        }
        
    }
    
    //画中间的基准线
    
    UIView* line = [[UIView alloc] initWithFrame:CGRectMake(40, 220, 240, 1)];
    
    line.backgroundColor = [UIColor redColor];
    
    [reader.view addSubview:line];
    
    //最上部view
    
    UIView* upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    
    upView.alpha = 0.3;
    
    upView.backgroundColor = [UIColor blackColor];
    
    [reader.view addSubview:upView];
    
    //用于说明的label
    
    labIntroudction= [[UILabel alloc] init];
    
    labIntroudction.backgroundColor = [UIColor clearColor];
    
    labIntroudction.frame=CGRectMake(15, 20, 290, 50);
    
    labIntroudction.numberOfLines=2;
    
    labIntroudction.textColor=[UIColor whiteColor];
    
    labIntroudction.text=@"将二维码图像置于矩形方框内，离手机摄像头10CM左右，系统会自动识别。";
    
    [upView addSubview:labIntroudction];
    
    
    //左侧的view
    
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 80, 20, 280)];
    
    leftView.alpha = 0.3;
    
    leftView.backgroundColor = [UIColor blackColor];
    
    [reader.view addSubview:leftView];
    
    
    //右侧的view
    
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(300, 80, 20, 280)];
    
    rightView.alpha = 0.3;
    
    rightView.backgroundColor = [UIColor blackColor];
    
    [reader.view addSubview:rightView];
    
    
    
    //底部view
    
    UIView * downView = [[UIView alloc] initWithFrame:CGRectMake(0, 360, 320, self.view.frame.size.height - 360)];
    
    downView.alpha = 0.3;
    
    downView.backgroundColor = [UIColor blackColor];
    
    [reader.view addSubview:downView];
    
    
    //用于取消操作的button
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    cancelButton.alpha = 0.4;
    
    [cancelButton setFrame:CGRectMake(20, 390, 280, 40)];
    
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    
    [cancelButton.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    
    [cancelButton addTarget:self action:@selector(dismissOverlayView:)forControlEvents:UIControlEventTouchUpInside];
    
    [reader.view addSubview:cancelButton];
    
}

//取消button方法

- (void)dismissOverlayView:(id)sender{
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        
    }];
}

#pragma mark ===  delegate  zbarReaderController


- (void) readerControllerDidFailToRead: (ZBarReaderController*) reader
                             withRetry: (BOOL) retry{
    
    [   self dismissViewControllerAnimated:YES completion:^{
        
    }];
    NSLog(@"失败了  ！~~~");
    
}

- (void) readerView: (ZBarReaderView*) readerView
     didReadSymbols: (ZBarSymbolSet*) symbols
          fromImage: (UIImage*) image{
    ;;;
}
 */


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    NSLog(@"取消相册 ！~~~");
    [self dismissViewControllerAnimated:YES completion:^{
        
        
    }];
    
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    /*
    if (![picker isKindOfClass:[ZBarReaderViewController class]]) {
        UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
        
        if (selectedImage) {
            self.userImage = selectedImage;
            [self.resultImageDict removeAllObjects];
            [self updateUI];
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        return;
    }
    

    
    id<NSFastEnumeration> results = [info objectForKey: ZBarReaderControllerResults];
    if ([info count]>2) {
        int quality = 0;
        ZBarSymbol *bestResult = nil;
        for(ZBarSymbol *sym in results) {
            int q = sym.quality;
            if(quality < q) {
                quality = q;
                bestResult = sym;
            }
        }
        [self performSelector: @selector(presentResult:) withObject: bestResult afterDelay: .001];
    }else {
        ZBarSymbol *symbol = nil;
        for(symbol in results)
            break;
        [self performSelector: @selector(presentResult:) withObject: symbol afterDelay: .001];
    }
    */
    
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    
    if (selectedImage) {
        self.userImage = selectedImage;
        [self.resultImageDict removeAllObjects];
        [self updateUI];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    return;
}

/*
- (void) presentResult: (ZBarSymbol*)sym {
    if (sym) {
        NSString *tempStr = sym.data;
        if ([sym.data canBeConvertedToEncoding:NSShiftJISStringEncoding]) {
            tempStr = [NSString stringWithCString:[tempStr cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
        }
        labIntroudction.text = tempStr;
    }
}






- (void)readFromAlbums{
    ZBarReaderController *reader = [ZBarReaderController new];
    reader.allowsEditing = YES;
    reader.readerDelegate = self;
    reader.showsZBarControls = NO;
    reader.showsHelpOnFail = NO;
    reader.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:reader animated:YES completion:^{
        NSLog(@"跳转成功---");
    }];
}
 */



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)qrImage {
    if (!_qrImage) {
        
        
        //  _qrImage = [[QRCodeGenerator shareInstance] qrImageForString:self.qrString imageSize:400 withMargin:2];
        QRCodeGenerator *qr=  [[QRCodeGenerator alloc] initWithRadius:0 withColor:[UIColor blackColor]];
        _qrImage = [qr qrImageForString:self.qrString
                                 Margin:0
                               Mode:0
                             OutputSize:self.resultView.bounds.size.width];
        
    }
    
    
    return _qrImage;
}

#pragma mark ==== Motion Effects ====

- (void)registerShadowEffectForView:(UIView *)aView depth:(CGFloat)depth;
{
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"shadowOffset.width"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"shadowOffset.height"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth;
{
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}

#pragma mark ==== UI Actions ====

- (void)updateUI {
    [self.pageControl updateCurrentPageDisplay];
    [self pageChanged:self.pageControl];
}

- (void)generateResultImageOfIndex:(NSInteger)index {
    UIImage *resultImage = [self composedImageWithEffectOfIndex:index];
    if (resultImage) {
        [self.resultImageDict setValue:resultImage forKey:effectNameKeys[index]];
        [self changeResultImage:resultImage];
    }
    
}

- (void)changeResultImage:(UIImage *)newImage {
    self.resultView.image = newImage;
}

- (IBAction)saveImage:(id)sender {
    if (self.resultView.image) {
        UIImageWriteToSavedPhotosAlbum(self.resultView.image, nil, nil, nil);
    }
}

- (IBAction)chooseColor:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        self.customedColor0 = [(UIButton *)sender backgroundColor];
        self.boardView.backgroundColor = self.customedColor0;
        [self.resultImageDict removeAllObjects];
        [self updateUI];
    }
}

- (IBAction)pageChanged:(id)sender {
    
    NSInteger currentIndex = self.pageControl.currentPage;
    self.title = effectNameKeys[currentIndex];
    
    UIImage *resultImage = self.resultImageDict[effectNameKeys[currentIndex]];
    if (resultImage) {
        [self changeResultImage:resultImage];
    } else {
        [self generateResultImageOfIndex:currentIndex];
    }
}

- (IBAction)swipeRight:(UISwipeGestureRecognizer *)swipeGestureRecognizer {
    if (self.pageControl.currentPage > 0) {
        self.pageControl.currentPage --;
    } else {
        self.pageControl.currentPage = self.pageControl.numberOfPages - 1;
    }
    
    [self pageChanged:self.pageControl];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)swipeGestureRecognizer {
    if (self.pageControl.currentPage < (self.pageControl.numberOfPages - 1)) {
        self.pageControl.currentPage ++;
    } else {
        self.pageControl.currentPage = 0;
    }
    
    [self pageChanged:self.pageControl];
}

#pragma mark ==== UIImagePicker ====
- (IBAction)takeAPicture:(id)sender {
    UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
    imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerVC.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    imagePickerVC.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    imagePickerVC.allowsEditing = YES;
    imagePickerVC.delegate = self;
    [self presentViewController:imagePickerVC animated:YES completion:^{
        
    }];
}

- (IBAction)pickAPicture:(id)sender {
    UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
    imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePickerVC.allowsEditing = YES;
    imagePickerVC.delegate = self;
    [self presentViewController:imagePickerVC animated:YES completion:^{
        
    }];
}

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
//   
//}

#pragma mark ==== ImageCompose ====

- (UIImage *)composedImageWithEffectOfIndex:(NSInteger)index {
    UIImage *resultImage = nil;
    
    if (!self.userImage) {
        return self.qrImage;
    }
    
    CGFloat qrWidth = self.userImage.size.width;
    
    if (0 == index) {
        // Popart : Portrait
        resultImage = [TRFilterGenerator printmakingWithImage:self.userImage
                                             maskWithQRString:self.qrString
                                                       margin:2
                                                       radius:0
                                                         mode:self.preferredQrLevel
                                                   outPutSize:qrWidth
                                                       color0:self.customedColor0
                                                       color1:[UIColor colorWithRed:1 green:0.96 blue:0.98 alpha:1]
                                                   detectFace:YES];
    } else if (1 == index) {
        // Popart : general
        resultImage = [TRFilterGenerator printmakingWithImage:self.userImage
                                             maskWithQRString:self.qrString
                                                       margin:2
                                                       radius:0.5
                                                         mode:self.preferredQrLevel
                                                   outPutSize:qrWidth
                                                       color0:self.customedColor0
                                                       color1:[UIColor colorWithRed:1 green:1 blue:1 alpha:1]
                                                   detectFace:NO];
        
    } else if (2 == index) {
        // Pixellate
        resultImage = [TRFilterGenerator qrEncodeWithAatarPixellate:self.userImage
                                                       qRString:self.qrString
                                                             margin:2
                                                               mode:self.preferredQrLevel
                                                             radius:0
                                                         outPutSize:qrWidth
                                                            qRColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        
    } else if (3 ==index) {
        // Circum : rounded corner
        resultImage  =[TRFilterGenerator qrEncodeWithCircle:self.userImage qRString:self.qrString margin:2 radius:0.5 outPutSize:qrWidth qRColor:nil];
    } else if (4 == index) {
        // Blur mask
        resultImage  = [TRFilterGenerator qrEncodeWithGussianBlur:self.userImage
                                                 maskWithQRString:self.qrString
                                                           margin:2
                                                           radius:0.5
                                                             mode:self.preferredQrLevel
                                                       outPutSize:qrWidth
                                                  monochromeColor:nil
                                             compositeWithTexture:nil];
    } else if (5 == index) {
        // Blur mask : textured
        resultImage  = [TRFilterGenerator qrEncodeWithGussianBlur:self.userImage
                                                 maskWithQRString:self.qrString
                                                           margin:2
                                                           radius:0.5
                                                             mode:self.preferredQrLevel
                                                       outPutSize:qrWidth
                                                  monochromeColor:[UIColor colorWithRed:0.87 green:0.66 blue:0.08 alpha:1]
                                             compositeWithTexture:[UIImage imageNamed:@"gold_texture.jpg"]];
    }
    
    return resultImage;
}

@end
