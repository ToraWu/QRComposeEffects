//
//  TRViewController.m
//  QRComposeEffects
//
//  Created by Tora on 13-11-27.
//  Copyright (c) 2013年 Tora Wu. All rights reserved.
//

#import "TRViewController.h"

@interface TRViewController ()

@property (nonatomic, strong) IBOutlet UIImageView *resultView;
@property (nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property (nonatomic, strong) IBOutlet UIView *boardView;

@property (nonatomic, strong) UIImage *qrImage;
@property (nonatomic, strong) UIImage *userImage;
@property (nonatomic, strong) NSMutableDictionary *resultImageDict;

@end

static NSArray *effectNameKeys;

@implementation TRViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (!effectNameKeys) {
        effectNameKeys = @[@"Mosaic", @"Circle Mosaic", @"Blur Mask"];
    }
    self.pageControl.numberOfPages = [effectNameKeys count];
    [self pageChanged:self.pageControl];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)generateResultImageOfIndex:(NSInteger)index {
    
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
}

@end
