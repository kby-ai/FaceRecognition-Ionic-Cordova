//
//  VideoViewController.m
//  sdkTest
//
//  Created by IanWong on 2019/10/9.
//  Copyright © 2019 com.SunYard.IanWong. All rights reserved.
//

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height



#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <UIKit/UIKit.h>
#import "facesdk.h"
#import "FaceView.h"

#import <Cordova/CDV.h>

#define THRESHOLD_REGISTER (0.78f)
#define THRESHOLD_VERIFY (0.78f)
#define THRESHOLD_LIVENESS (0.7f)

extern NSMutableDictionary* g_user_list;

@interface VideoViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) FaceView *faceView;
@property (strong, nonatomic) CDVInvokedUrlCommand *command;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, assign) int currentCamPos;
@property (nonatomic, assign) int mode;
@property (nonatomic, assign) int register_;

@end

@implementation VideoViewController

- (void)setArgment: (int)mode cam_id:(int)cam_id {
    self.mode = mode;
    
    if(cam_id == 0) {
        self.currentCamPos = AVCaptureDevicePositionFront;
    } else {
        self.currentCamPos = AVCaptureDevicePositionBack;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
                  
    _queue = dispatch_queue_create("net.bujige.testQueue", NULL);
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *deviceF;
    for (AVCaptureDevice *device in devices )
    {
        if ( device.position == self.currentCamPos )
        {
            deviceF = device;
            break;
        }
    }

    if ([deviceF isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error = nil;
        if ([deviceF lockForConfiguration:&error]) {
            CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
            [deviceF setExposurePointOfInterest:exposurePoint];
            [deviceF setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
    }
    if ([deviceF isFocusModeSupported:AVCaptureFocusModeLocked]) {
        NSError *error = nil;
        if ([deviceF lockForConfiguration:&error]) {
            deviceF.focusMode = AVCaptureFocusModeLocked;
            [deviceF unlockForConfiguration];
        }
        else {
        }
    }
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceF error:nil];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    
    [output setSampleBufferDelegate:self queue: _queue];
    //    AVCaptureMetadataOutput *metaout = [[AVCaptureMetadataOutput alloc] init];
    //    [metaout setMetadataObjectsDelegate:self queue:_faceQueue];
    self.session = [[AVCaptureSession alloc] init];
    [self.session beginConfiguration];
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    if ([self.session canAddOutput:output]) {
        [self.session addOutput:output];
    }
    [self.session commitConfiguration];
    
    NSString     *key           = (NSString *)kCVPixelBufferPixelFormatTypeKey;
    NSNumber     *value         = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:value forKey:key];
    [output setVideoSettings:videoSettings];

    AVCaptureSession* session = (AVCaptureSession *)self.session;
    
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            
            if (av.supportsVideoMirroring) {
                
                av.videoOrientation = AVCaptureVideoOrientationPortrait;
                av.videoMirrored = YES;
            }
        }
    }
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.previewLayer.frame = (CGRect){CGPointZero, [UIScreen mainScreen].bounds.size};
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.previewLayer];
    [self.session startRunning];
    
    self.faceView = [[FaceView alloc]initWithFrame:self.view.bounds];
    self.faceView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.faceView];
    
    if(self.mode == 0) {
        UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 200) / 2, self.view.bounds.size.height - 150, 200, 50)];
        [button setBackgroundColor:[UIColor redColor]];
        [button setTitle:@"Register" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(registerClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        NSString* switch_icon_path = [[NSBundle mainBundle] pathForResource:@"ic_switch.png" ofType:nil];
        UIImage* switch_icon = [UIImage imageWithContentsOfFile:switch_icon_path];
        UIButton* switch_button = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 20, 50, 50)];
        [switch_button setBackgroundImage:switch_icon forState:UIControlStateNormal];
        [switch_button addTarget:self action:@selector(switchClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:switch_button];
    }
}

- (void)registerClicked:(UIButton *)button {
     NSLog(@"Button Pressed");
    self.register_ = 1;
}

- (void)switchClicked:(UIButton *)button {
     NSLog(@"Switch Pressed");
    
    if(self.currentCamPos == AVCaptureDevicePositionFront) {
        self.currentCamPos = AVCaptureDevicePositionBack;
    } else {
        self.currentCamPos = AVCaptureDevicePositionFront;
    }
    
    [self.session stopRunning];
    NSArray* inputs = [self.session inputs];
    for(AVCaptureDeviceInput* input in inputs) {
        [self.session removeInput:input];
    }
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *deviceF;
    for (AVCaptureDevice *device in devices)
    {
        if ( device.position == self.currentCamPos )
        {
            deviceF = device;
            break;
        }
    }
    
    if ([deviceF isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error = nil;
        if ([deviceF lockForConfiguration:&error]) {
            CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
            [deviceF setExposurePointOfInterest:exposurePoint];
            [deviceF setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
    }
    if ([deviceF isFocusModeSupported:AVCaptureFocusModeLocked]) {
        NSError *error = nil;
        if ([deviceF lockForConfiguration:&error]) {
            deviceF.focusMode = AVCaptureFocusModeLocked;
            [deviceF unlockForConfiguration];
        }
        else {
        }
    }
    
    AVCaptureDeviceInput*input = [[AVCaptureDeviceInput alloc] initWithDevice:deviceF error:nil];
    [self.session beginConfiguration];
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }

    [self.session commitConfiguration];
    
    AVCaptureSession* session = (AVCaptureSession *)self.session;
    
    for (AVCaptureVideoDataOutput* output in session.outputs) {
        for (AVCaptureConnection * av in output.connections) {
            
            if (av.supportsVideoMirroring) {
                
                av.videoOrientation = AVCaptureVideoOrientationPortrait;
                av.videoMirrored = YES;
            }
        }
    }
    [self.session startRunning];
}



- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                             width,
                             height,
                             8,
                             bytesPerRow,
                             colorSpace,
                             kCGBitmapByteOrder32Little
                             | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    //UIImage *image = [UIImage imageWithCGImage:quartzImage];
    UIImage *image = [UIImage imageWithCGImage:quartzImage
                              scale:1.0f
                            orientation:UIImageOrientationUp];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (UIImage *)croppIngimageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return cropped;
}

- (void)closeCamera {
    if(self.session != nil && self.session.isRunning) {
        [self.session stopRunning];
        self.session = nil;
    }

    // Remove preview layer
    if(self.previewLayer != nil) {
        [self.previewLayer removeFromSuperlayer];
        self.previewLayer = nil;
    }

    // Remove faceView
    if(self.faceView != nil) {
        [self.faceView removeFromSuperview];
        self.faceView = nil;
    }
}


#pragma mark AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    NSMutableArray* face_results = [FaceSDK faceDetection:image];
    
    if(face_results.count == 1) {
        FaceBox* face = [face_results objectAtIndex:0];
        NSData* feature = [FaceSDK templateExtraction:image faceBox:face];

        if(self.mode == 0) {
            if(self.register_ == 1 && feature != nil) {
                self.register_ = 0;

                // Get NSString from NSData object in Base64
                NSString* encoddedFeature = [feature base64EncodedStringWithOptions:0];

                UIImage* crop_image = [self croppIngimageByImageName:image toRect:CGRectMake(face.x1, face.y1, face.x2 - face.x1, face.y2 - face.y1)];
                NSData* image_data = UIImageJPEGRepresentation(crop_image, 1.0);
                NSString* encoddedImage = [image_data base64EncodedStringWithOptions:0];
                
                NSString* maxScoreId = @"";
                float maxScore = 0;
                NSString* existsID = @"";
                for(NSString* key in g_user_list) {
                    NSString* registered_feat = [g_user_list objectForKey:key];
                    NSData* registered_data = [[NSData alloc] initWithBase64EncodedString:registered_feat options:0];
                    
                    float score = [FaceSDK similarityCalculation:feature templates2:registered_data];
                    if(maxScore < score) {
                        maxScore = score;
                        maxScoreId = key;
                    }
                }
                
                if(maxScore > THRESHOLD_REGISTER) {
                    existsID = maxScoreId;
                }
               
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:true completion:^{
                        if(self.delegate != nil) {
                            
                            NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
                            [dict setValue:encoddedFeature forKey:@"data"];
                            [dict setValue:encoddedImage forKey:@"image"];
                            [dict setValue:existsID forKey:@"exists"];
                            
                            [self.delegate onRegistered: dict];
                        }
                    }];
                });
            }
        } else if(self.mode == 1) {
            
            NSString* existsID = @"";
            NSString* maxScoreId = @"";
            float maxScore = 0;
            for(NSString* key in g_user_list) {
                NSString* registered_feat = [g_user_list objectForKey:key];
                NSData* registered_data = [[NSData alloc] initWithBase64EncodedString:registered_feat options:0];
                
                float score = [FaceSDK similarityCalculation:feature templates2:registered_data];
                if(maxScore < score) {
                    maxScore = score;
                    maxScoreId = key;
                }
            }
            
            if(maxScore > THRESHOLD_VERIFY) {
                existsID = maxScoreId;
            }
            
            NSMutableDictionary* face_boundary = [[NSMutableDictionary alloc] init];
            [face_boundary setValue:[NSNumber numberWithInt:face.x1] forKey:@"left"];
            [face_boundary setValue:[NSNumber numberWithInt:face.y1] forKey:@"top"];
            [face_boundary setValue:[NSNumber numberWithInt:face.x2] forKey:@"right"];
            [face_boundary setValue:[NSNumber numberWithInt:face.y2] forKey:@"bottom"];
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
            [dict setValue:face_boundary forKey:@"face_boundary"];
            [dict setValue:existsID forKey:@"face_id"];
            [dict setValue:[NSNumber numberWithInt:face.liveness > THRESHOLD_LIVENESS ? 1 : 0] forKey:@"liveness"];
            [dict setValue:[NSNumber numberWithInt:face_results.count] forKey:@"face_count"];
            
            [self.delegate onRecognized:dict];
        }
    } else if(face_results.count > 1) {
        FaceBox* face = (FaceBox*)[face_results objectAtIndex:0];

        if(self.mode == 1) {
            NSMutableDictionary* face_boundary = [[NSMutableDictionary alloc] init];
            [face_boundary setValue:[NSNumber numberWithInt:face.x1] forKey:@"left"];
            [face_boundary setValue:[NSNumber numberWithInt:face.y1] forKey:@"top"];
            [face_boundary setValue:[NSNumber numberWithInt:face.x2] forKey:@"right"];
            [face_boundary setValue:[NSNumber numberWithInt:face.y2] forKey:@"bottom"];
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
            [dict setValue:face_boundary forKey:@"face_boundary"];
            [dict setValue:@"" forKey:@"face_id"];
            [dict setValue:[NSNumber numberWithInt:0] forKey:@"liveness"];
            [dict setValue:[NSNumber numberWithInt:face_results.count] forKey:@"face_count"];
            
            [self.delegate onRecognized:dict];
        }
    } else if(face_results.count == 0) {
        if(self.mode == 1) {
            NSMutableDictionary* face_boundary = [[NSMutableDictionary alloc] init];
            [face_boundary setValue:[NSNumber numberWithInt:-1] forKey:@"left"];
            [face_boundary setValue:[NSNumber numberWithInt:-1] forKey:@"top"];
            [face_boundary setValue:[NSNumber numberWithInt:-1] forKey:@"right"];
            [face_boundary setValue:[NSNumber numberWithInt:-1] forKey:@"bottom"];
            
            NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
            [dict setValue:face_boundary forKey:@"face_boundary"];
            [dict setValue:@"" forKey:@"face_id"];
            [dict setValue:[NSNumber numberWithInt:0] forKey:@"liveness"];
            [dict setValue:[NSNumber numberWithInt:0] forKey:@"face_count"];
            
            [self.delegate onRecognized:dict];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        //  self.imageView.image  = [self drawFaces:face_info InImage:image];
         [self.faceView setFrameSize: image.size];
         [self.faceView setFaceResults:face_results];
    });
}


- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)shouldAutorotate {
    return NO;
}
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"mem out");
    // Dispose of any resources that can be recreated.
}

@end
