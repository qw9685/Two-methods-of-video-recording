//
//  cameraManager.h
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/1/22.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FileOutModel.h"

@protocol FileOutManagerDelegate<NSObject>

//录制时间
- (void)cameraRecordingTime:(float)time;

- (void)didStartRecording;

- (void)didFinishRecording;

@end

@interface FileOutManager : NSObject

@property (nonatomic, assign) NSURL* fileUrl;

@property (nonatomic, assign) BOOL isRecording;//是否是录制状态

@property (nonatomic, assign) BOOL stabilizedModel;//防抖功能

@property (nonatomic, weak) id <FileOutManagerDelegate> delegate;

//开始捕获
+ (FileOutManager*)initCameraWithlayer:(CALayer*)layer;

- (void)stopRunning;

- (void)startRecord;
- (void)stopRecord;

//闪光灯
- (void)FlashState:(FlashState)flashState;
//分辨率设置
- (void)setCameraResolution:(resolutionType)type;
//切换摄像头
- (void)cameraPosition:(cameraPosition)position;

//聚焦点
- (void)setFocusCursorWithPoint:(CGPoint)point;
//设置焦距
- (void)videoScaleAndCropFactor:(float)scale;
// 调节ISO，光感度 0.0-1.0
- (void)cameraBackgroundDidChangeISO:(CGFloat)iso;
//设置帧率
- (void)setFpsWithMaxFps:(int)MaxFps MinFps:(int)MinFps;
//横竖屏切换
- (void)setVideoOrientation:(videoOrientation)videoOrientation;

@end
