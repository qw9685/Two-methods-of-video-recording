//
//  assetWriterModel.h
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/3/1.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>

@protocol assetWriterModelDelegate <NSObject>

- (void)recordProgress:(CGFloat)progress;

@end

@interface assetWriterModel : NSObject

@property (atomic, assign) NSInteger videoHeight;//视频分辨的宽
@property (atomic, assign) NSInteger videoWeight;//视频分辨的高
@property (atomic, assign) NSInteger frameRate;//视频帧率
@property (atomic, assign) NSInteger videoRate;//视频码率
@property (atomic, assign) int channels;//音频通道
@property (atomic, assign) Float64 samplerate;//音频采样率
@property (atomic, assign) Float64 audioBitRate;//音频比特率

@property (atomic, assign, readonly) BOOL isCapturing;//正在录制
@property (atomic, assign, readonly) BOOL isPaused;//是否暂停
@property (atomic, assign, readonly) CGFloat currentRecordTime;//当前录制时间
@property (atomic, assign) CGFloat maxRecordTime;//录制最长时间
@property (atomic, strong) NSString *videoPath;//视频路径
@property (nonatomic, weak) id<assetWriterModelDelegate>delegate;

+ (assetWriterModel*)initCameraWithlayer:(CALayer*)layer;

//关闭录制功能
- (void)shutdown;
//开始录制
- (void) startCapture;
//暂停录制
- (void) pauseCapture;
//停止录制
- (void) stopCaptureHandler:(void (^)(UIImage *movieImage))handler;
//继续录制
- (void) resumeCapture;


@end
