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

@interface TRViewController () {
    UIImage *_qrImage;
}

@property (nonatomic, strong) IBOutlet UIImageView *resultView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIView *boardView;

@property (nonatomic, readonly) UIImage *qrImage;
@property (nonatomic, strong) UIImage *userImage;
@property (nonatomic, strong) NSMutableDictionary *resultImageDict;
@property (nonatomic, copy) NSString *qrString;

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
        effectNameKeys = @[@"CIPixellate",@"Mosaic", @"Circle Mosaic", @"Blur Mask"];
    }
    self.pageControl.numberOfPages = [effectNameKeys count];
    
    self.qrString = @"http://roundqr.sinaapp.com/index.php";
    
    // Motion Effects
    self.boardView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.boardView.layer.shadowOffset = CGSizeMake(0,2);
    self.boardView.layer.shadowOpacity = 0.5;
    self.boardView.layer.shadowRadius = 10;
    [self registerEffectForView:self.boardView depth:-10];
    [self registerShadowEffectForView:self.boardView depth:4*self.boardView.layer.shadowRadius];
    
    
    self.resultView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.resultView.layer.shadowOffset = CGSizeMake(0,-2);
    self.resultView.layer.shadowOpacity = 0.5;
    self.resultView.layer.shadowRadius = 5;
    [self registerEffectForView:self.resultView depth:5];
    [self registerShadowEffectForView:self.resultView depth:-4*self.resultView.layer.shadowRadius];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateUI];
}

- (UIImage *)qrImage {
    if (!_qrImage) {
 
      //  _qrImage = [[QRCodeGenerator shareInstance] qrImageForString:self.qrString imageSize:400 withMargin:2];
        _qrImage = [[QRCodeGenerator shareInstance] qrImageForString:self.qrString withPixSize:16 withMargin:2 withMode:0 withOutputSize:400];
 
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
        [self pageChanged:self.pageControl];
    }
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)swipeGestureRecognizer {
    if (self.pageControl.currentPage < (self.pageControl.numberOfPages - 1)) {
        self.pageControl.currentPage ++;
        [self pageChanged:self.pageControl];
    }
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    
    if (selectedImage) {
        self.userImage = selectedImage;
        [self updateUI];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
    
//    test
    
    self.resultView.image =[TRFilterGenerator qrEncodeWithCircle:selectedImage withQRString:@"我是二维码 快来扫我啊 你快扫我啊 看到我了么？ 我 真的是二维码啊" withMargin:0];

}

#pragma mark ==== ImageCompose ====

- (UIImage *)composedImageWithEffectOfIndex:(NSInteger)index {
    UIImage *resultImage = nil;
    
    if (!self.userImage) {
        return self.qrImage;
    }
    
    CIImage *scrImage = [CIImage imageWithCGImage:self.userImage.CGImage];
    
    if (0 == index) {
 
 
//       return  [TRFilterGenerator qrEncodeWithAatarPixellate:self.userImage withQRString:@"我是二维码 赶紧扫我啊 你倒是扫啊" withMargin:0 withMode:0];
        
 
//        resultImage = self.userImage;
 
    } else if (1 == index) {
//        resultImage = [TRFilterGenerator qrEncodeWithAatarPixellate:self.userImage withQRString:self.qrString];
 
 
    } else if (2 == index) {
        // Apply clamp filter:
        
        NSString *clampFilterName = @"CIAffineClamp";
        CIFilter *clamp = [CIFilter filterWithName:clampFilterName];
        
        [clamp setValue:scrImage
                 forKey:kCIInputImageKey];
        
        CIImage *clampResult = [clamp valueForKey:kCIOutputImageKey];
        
        
        // Apply Gaussian Blur filter
        
        NSString *gaussianBlurFilterName = @"CIGaussianBlur";
        CIFilter *gaussianBlur           = [CIFilter filterWithName:gaussianBlurFilterName];
        
        [gaussianBlur setValue:clampResult
                        forKey:kCIInputImageKey];
        [gaussianBlur setValue:[NSNumber numberWithFloat:20.0]
                        forKey:@"inputRadius"];
        
        CIImage *gaussianBlurResult = [gaussianBlur valueForKey:kCIOutputImageKey];
        
        // Adjust Brightness of frontground
        NSString *colorControlFilterName = @"CIColorControls";
        CIFilter *colorControl = [CIFilter filterWithName:colorControlFilterName];
        [colorControl setValue:gaussianBlurResult forKey:kCIInputImageKey];
        [colorControl setValue:@(0.15) forKey:kCIInputBrightnessKey];
        CIImage *frontground = [colorControl valueForKey:kCIOutputImageKey];
        
        // Adjust Brightness of background
        CIFilter *bgcolorControl = [CIFilter filterWithName:colorControlFilterName];
        [bgcolorControl setValue:scrImage forKey:kCIInputImageKey];
        [bgcolorControl setValue:@(-0.15) forKey:kCIInputBrightnessKey];
        CIImage *background = [bgcolorControl valueForKey:kCIOutputImageKey];
        
        
        // Compose with Mask filter
        NSString *maskFilterName = @"CIBlendWithAlphaMask";
        CIFilter *mask = [CIFilter filterWithName:maskFilterName];
 
        
//        CIImage *maskImage = [CIImage imageWithCGImage:[[QRCodeGenerator shareInstance] qrImageForString:self.qrString imageSize:self.userImage.size.width withMargin:2  withOutputSize:(float)outImagesize].CGImage];
        
         CIImage *maskImage = [CIImage imageWithCGImage:[[QRCodeGenerator shareInstance] qrImageForString:self.qrString withPixSize:16 withMargin:2 withMode:0 withOutputSize:0].CGImage];
                               
 
        [mask setValue:frontground forKey:kCIInputImageKey];
        [mask setValue:maskImage forKey:kCIInputMaskImageKey];
        [mask setValue:background forKey:kCIInputBackgroundImageKey];
        CIImage *maskResult = [mask valueForKey:kCIOutputImageKey];
        
        resultImage = [UIImage imageWithCGImage:[self.ciContext createCGImage:maskResult
                                           fromRect:scrImage.extent]];
    }
    
    return resultImage;
}

@end
