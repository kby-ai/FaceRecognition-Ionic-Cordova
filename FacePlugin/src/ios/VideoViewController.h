//
//  VideoViewController.h
//  sdkTest
//
//  Created by IanWong on 2019/10/9.
//  Copyright © 2019 com.SunYard.IanWong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>

NS_ASSUME_NONNULL_BEGIN

@protocol VideoViewControllerDelegate<NSObject>

-(void)onRegistered:(NSMutableDictionary*) data;;
-(void)onRecognized:(NSMutableDictionary*) data;

@end

@interface VideoViewController : UIViewController
@property (nonatomic, weak) id<VideoViewControllerDelegate> delegate;

- (void)setArgment: (int)mode cam_id:(int)cam_id;
@end

NS_ASSUME_NONNULL_END
