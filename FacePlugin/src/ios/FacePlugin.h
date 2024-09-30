#import <Cordova/CDV.h>
#import "VideoViewController.h"


@interface FacePlugin : CDVPlugin<VideoViewControllerDelegate>

@property (strong, nonatomic) CDVInvokedUrlCommand *command;


- (void) face_register:(CDVInvokedUrlCommand*)command;
- (void) face_recognize:(CDVInvokedUrlCommand *)command;
- (void) update_data:(CDVInvokedUrlCommand *)command;
- (void) clear_data:(CDVInvokedUrlCommand *)command;
- (void) set_activation:(CDVInvokedUrlCommand *)command;
@end
