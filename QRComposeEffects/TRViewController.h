//
//  TRViewController.h
//  QRComposeEffects
//
//  Created by Tora on 13-11-27.
//  Copyright (c) 2013年 Tora Wu. All rights reserved.
//
#import "ZBarSDK.h"
#import <UIKit/UIKit.h>

@interface TRViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate,ZBarReaderDelegate,ZBarCaptureDelegate>
{

    UILabel * labIntroudction;
}
@end
