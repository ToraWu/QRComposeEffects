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
        effectNameKeys = @[@"Pixellate",@"Pixellate Gold",@"Pixellate Liquid", @"Circum", @"Circum Liquid", @"Transparent Blur", @"TransBlur Gold"];
    }
    self.resultImageDict = [NSMutableDictionary new];
    self.pageControl.numberOfPages = [effectNameKeys count];
    
    // Sample data
    self.qrString = @"http://roundqr.sinaapp.com/index.php";
    self.userImage = [UIImage imageNamed:@"IMG_5623.JPG"];
    
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
      QRCodeGenerator *qr=  [[QRCodeGenerator alloc] initWithRadius:0 withColor:[UIColor blackColor]];
        _qrImage = [qr qrImageForString:self.qrString withMargin:0 withMode:0 withOutputSize:self.resultView.bounds.size.width];
 
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *selectedImage = info[UIImagePickerControllerEditedImage];
    
    if (selectedImage) {
        self.userImage = selectedImage;
        [self.resultImageDict removeAllObjects];
        [self updateUI];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

#pragma mark ==== ImageCompose ====

- (UIImage *)composedImageWithEffectOfIndex:(NSInteger)index {
    UIImage *resultImage = nil;
    
    if (!self.userImage) {
        return self.qrImage;
    }
    
    CGFloat qrWidth = self.userImage.size.width;
    
    if (0 == index) {
        // Pixellate
        resultImage = [TRFilterGenerator qrEncodeWithAatarPixellate:self.userImage withQRString:self.qrString withMargin:2 withMode:5 withRadius:0  withOutPutSize:qrWidth withQRColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
        
    } else if (1 == index) {
        // Pixellate : Golden
        resultImage  = [TRFilterGenerator qrEncodeWithAatarPixellate:self.userImage withQRString:self.qrString withMargin:0 withMode:0 withRadius:0 withOutPutSize:qrWidth withQRColor:[UIColor colorWithRed:255.0/255.0 green:235/255.0 blue:2.0/255.0 alpha:1]];

    } else if (2 == index) {
        // Pixellate : rounded corner
        resultImage  = [TRFilterGenerator qrEncodeWithAatarPixellate:self.userImage withQRString:self.qrString withMargin:2 withMode:0 withRadius:0.5 withOutPutSize:qrWidth withQRColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    
    } else if (3 == index) {
        // Circum
        resultImage = [TRFilterGenerator qrEncodeWithCircle:self.userImage withQRString:self.qrString withMargin:1 withRadius:0 withOutPutSize:qrWidth withQRColor:[UIColor blackColor]];
    }
    else if (4 ==index) {
        // Circum : rounded corner
        resultImage  = [TRFilterGenerator qrEncodeWithCircle:self.userImage withQRString:self.qrString withMargin:2 withRadius:0.5 withOutPutSize:qrWidth withQRColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:1]];
    }
    else if (5 == index) {
        // Blur mask
        resultImage  = [TRFilterGenerator qrEncodeWithGussianBlur:self.userImage withQRString:self.qrString withMargin:2 withRadius:1.0 withOutPutSize:qrWidth withQRColor:nil];
    } else if (6 == index) {
        // Blur mask : golden
        resultImage  = [TRFilterGenerator qrEncodeWithGussianBlur:self.userImage withQRString:self.qrString withMargin:2 withRadius:1.0 withOutPutSize:qrWidth withQRColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.1 alpha:1]];
    }
    
    return resultImage;
}

@end
