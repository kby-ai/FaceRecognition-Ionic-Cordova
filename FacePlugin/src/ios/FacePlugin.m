#import "FacePlugin.h"
#import "VideoViewController.h"
#import "facesdk.h"

#define THRESHOLD_REGISTER (0.78f)

NSMutableDictionary* g_user_list;

@implementation FacePlugin

- (void) face_register:(CDVInvokedUrlCommand *)command
{
    if(g_user_list == nil) {
        g_user_list = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary* jsonData = [command.arguments objectAtIndex:0];
    NSString* cam_id = [jsonData objectForKey:@"cam_id"];
    
    self.command = command;
    
    VideoViewController *conttroller = [[VideoViewController alloc]init];
    [conttroller setArgment:0 cam_id:[cam_id intValue]];
    conttroller.delegate = self;
    [self.viewController presentViewController:conttroller animated:YES completion:nil];
}

- (void) face_recognize:(CDVInvokedUrlCommand *)command
{
    if(g_user_list == nil) {
        g_user_list = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary* jsonData = [command.arguments objectAtIndex:0];
    NSString* cam_id = [jsonData objectForKey:@"cam_id"];
    
    self.command = command;
    
    VideoViewController *conttroller = [[VideoViewController alloc]init];
    [conttroller setArgment:1 cam_id:[cam_id intValue]];
    conttroller.delegate = self;
    [self.viewController presentViewController:conttroller animated:YES completion:nil];
}

- (void) update_data:(CDVInvokedUrlCommand *)command
{
    if(g_user_list == nil) {
        g_user_list = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableDictionary* jsonData = [command.arguments objectAtIndex:0];
    NSArray* userList = [jsonData objectForKey:@"user_list"];
    
    for(int i = 0; i < [userList count]; i ++) {
        NSMutableDictionary* user = [userList objectAtIndex:i];
        NSString* face_id = [user objectForKey:@"face_id"];
        NSString* face_data = [user objectForKey:@"data"];
        g_user_list[face_id] = face_data;
    }
}

- (void) clear_data:(CDVInvokedUrlCommand *)command
{
    if(g_user_list == nil) {
        g_user_list = [[NSMutableDictionary alloc] init];
    }
    
    [g_user_list removeAllObjects];
}

- (void) set_activation:(CDVInvokedUrlCommand *)command
{
    if(g_user_list == nil) {
        g_user_list = [[NSMutableDictionary alloc] init];
    }

    NSMutableDictionary* jsonData = [command.arguments objectAtIndex:0];
    NSString* license = [jsonData objectForKey:@"license"];

    NSLog(@"license: %@", license);
    
    int ret = [FaceSDK setActivation:license];
    NSLog(@"set activation result: %d", ret);
    
    [FaceSDK initSDK];
}

- (void) close_camera:(CDVInvokedUrlCommand *)command
{
    self.command = command;

    // Dismiss the video controller if it's presented
    dispatch_async(dispatch_get_main_queue(), ^{
        VideoViewController *controller = (VideoViewController *)self.viewController.presentedViewController;
        if ([controller isKindOfClass:[VideoViewController class]]) {
            [controller closeCamera];
        }
        
        [self.viewController dismissViewControllerAnimated:YES completion:^{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Camera closed"];
            [self.commandDelegate sendPluginResult:result callbackId:self.command.callbackId];
        }];
    });
}

- (UIImage *)cropAndResizeImage:(UIImage *)image toRect:(CGRect)rect size:(CGSize)size {
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    // Resize to desired size
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [cropped drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

- (void) face_register_from_image:(CDVInvokedUrlCommand *)command
{
    self.command = command;
    
    NSMutableDictionary* jsonData = [command.arguments objectAtIndex:0];
    NSString* base64Image = [jsonData objectForKey:@"image"];

    if(g_user_list == nil) {
        g_user_list = [[NSMutableDictionary alloc] init];
    }

    // Remove data URL prefix if present
    if ([base64Image hasPrefix:@"data:image"]) {
        NSRange commaRange = [base64Image rangeOfString:@","];
        if (commaRange.location != NSNotFound) {
            base64Image = [base64Image substringFromIndex:commaRange.location + 1];
        }
    }

    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64Image options:0];
    UIImage *image = [UIImage imageWithData:imageData];

    // Face detection with liveness check
    NSMutableArray* faceResults = [FaceSDK faceDetection:image]; // add liveness param if available

    if(faceResults == nil || faceResults.count == 0) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No face detected"];
        [self.commandDelegate sendPluginResult:result callbackId:self.command.callbackId];
        return;
    }

    if(faceResults.count == 1) {
        FaceBox* face = [faceResults objectAtIndex:0];

        // Extract template
        NSData* feature = [FaceSDK templateExtraction:image faceBox:face];

        // Crop the face (similar to Android getBestRect)
        CGRect cropRect = CGRectMake(face.x1, face.y1, face.x2 - face.x1, face.y2 - face.y1);
        UIImage *croppedImage = [self cropAndResizeImage:image toRect:cropRect size:CGSizeMake(120, 120)];


        // Encode image and feature
        NSData* croppedImageData = UIImagePNGRepresentation(croppedImage);
        NSString* encodedImage = [croppedImageData base64EncodedStringWithOptions:0];
        NSString* encodedFeature = [feature base64EncodedStringWithOptions:0];

        // Check duplicates
        NSString* maxScoreId = @"";
        float maxScore = 0;
        NSString* existsID = @"";

        for(NSString* key in g_user_list) {
            NSString* registeredFeature = [g_user_list objectForKey:key];
            NSData* registeredData = [[NSData alloc] initWithBase64EncodedString:registeredFeature options:0];

            float score = [FaceSDK similarityCalculation:feature templates2:registeredData];
            if(score > maxScore) {
                maxScore = score;
                maxScoreId = key;
            }
        }

        if(maxScore > THRESHOLD_REGISTER) {
            existsID = maxScoreId;
        }

        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setValue:encodedFeature forKey:@"data"];
        [dict setValue:encodedImage forKey:@"image"];
        [dict setValue:existsID forKey:@"exists"];

        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict];
        [self.commandDelegate sendPluginResult:result callbackId:self.command.callbackId];
    } else {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Multiple faces detected"];
        [self.commandDelegate sendPluginResult:result callbackId:self.command.callbackId];
    }
}


#pragma mark - VideoViewControllerDelegate
-(void) onRegistered:(NSMutableDictionary*) data {
    
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    [self.commandDelegate sendPluginResult:result callbackId:self.command.callbackId];
}


-(void)onRecognized:(NSMutableDictionary*) data {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    [result setKeepCallbackAsBool:true];
    [self.commandDelegate sendPluginResult:result callbackId:self.command.callbackId];
}

@end
