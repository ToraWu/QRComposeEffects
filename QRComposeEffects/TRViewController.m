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
@interface TRViewController ()

@property (nonatomic, strong) IBOutlet UIImageView *resultView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIView *boardView;

@property (nonatomic, strong) UIImage *qrImage;
@property (nonatomic, strong) UIImage *userImage;
@property (nonatomic, strong) NSMutableDictionary *resultImageDict;

@property (nonatomic, strong) CIContext *ciContext;

@end

static NSArray *effectNameKeys;

@implementation TRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    EAGLContext *myEAGLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    self.ciContext  = [CIContext contextWithEAGLContext:myEAGLContext options:nil];
    
    if (!effectNameKeys) {
        effectNameKeys = @[@"Mosaic", @"Circle Mosaic", @"Blur Mask"];
    }
    self.pageControl.numberOfPages = [effectNameKeys count];
    [self pageChanged:self.pageControl];
    
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
        //test
        [self changeResultImage:selectedImage];
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
        return nil;
    }
    
    CIImage *scrImage = [CIImage imageWithCGImage:self.userImage.CGImage];
    
    if (0 == index) {
        
    } else if (1 == index) {
        
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
        [gaussianBlur setValue:[NSNumber numberWithFloat:3.0]
                        forKey:@"inputRadius"];
        
        CIImage *gaussianBlurResult = [gaussianBlur valueForKey:kCIOutputImageKey];
        
        // Apply Mask filter
        
        NSString *maskFilterName = @"CIBlendWithMask";
        
        resultImage = [UIImage imageWithCGImage:[self.ciContext createCGImage:gaussianBlurResult
                                           fromRect:scrImage.extent]];
    }
    
    return resultImage;
}

@end
