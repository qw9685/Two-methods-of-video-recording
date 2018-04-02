//
//  FileOutModel.h
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/8.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, resolutionType)
{
    resolution_1280x720 = 0,
    resolution_1920x1080,
    resolution_3840x2160
    
};

typedef NS_ENUM(NSInteger, FlashState) {
    FlashClose = 0,
    FlashOpen,
    FlashAuto,
};

typedef NS_ENUM(NSInteger, cameraPosition) {
    PositionUnspecified = 0,
    PositionPositionBack,
    PositionPositionFront,
};


typedef NS_ENUM(NSInteger, videoOrientation) {
    VideoOrientationPortrait = 0,
    VideoOrientationLandscapeLeft,
    VideoOrientationLandscapeRight,
};

@protocol FileOutModelDelegate<NSObject>

//录制时间
- (void)cameraRecordingTime:(float)time;

- (void)didStartRecording;

- (void)didFinishRecording;

@end

@interface FileOutModel : NSObject

@property (nonatomic, strong) NSURL* fileUrl;
@property (nonatomic, assign) BOOL isRecording;//是否是录制状态
@property (nonatomic, assign) resolutionType resolutionType;//分辨率
@property (nonatomic, assign) FlashState FlashState;//闪光灯状态
@property (nonatomic, assign) cameraPosition cameraPosition;//摄像头方向
@property (nonatomic, assign) videoOrientation videoOrientation;
    
@property (nonatomic, assign) BOOL stabilizedModel;//防抖功能
@property (nonatomic, weak) id <FileOutModelDelegate> delegate;

+ (FileOutModel*)initCameraWithlayer:(CALayer*)layer;

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
    
@end
