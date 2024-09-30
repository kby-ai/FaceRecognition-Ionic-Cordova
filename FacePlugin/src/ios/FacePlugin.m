#import "FacePlugin.h"
#import "VideoViewController.h"
#import "facesdk.h"

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
