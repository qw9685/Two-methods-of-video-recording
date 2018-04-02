//
//  cameraManager.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/1/22.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "FileOutManager.h"

@interface FileOutManager()<FileOutModelDelegate>
@property (nonatomic, strong) FileOutModel* fileOutmodel;
@end

@implementation FileOutManager

-(BOOL)isRecording{
    return self.fileOutmodel.isRecording;
}

-(void)setFileUrl:(NSURL *)fileUrl{
    self.fileOutmodel.fileUrl = fileUrl;
}

-(void)setStabilizedModel:(BOOL)stabilizedModel{
    _stabilizedModel = stabilizedModel;
    self.fileOutmodel.stabilizedModel = stabilizedModel;
}

//开始捕获
+ (FileOutManager*)initCameraWithlayer:(CALayer*)layer{
    
    FileOutManager* manager = [FileOutManager new];
    manager.fileOutmodel = [FileOutModel initCameraWithlayer:layer];
    manager.fileOutmodel.delegate = manager;
    
    return manager;
}

- (void)stopRunning{
    [self.fileOutmodel stopRunning];
}

- (void)startRecord{
    
    [self.fileOutmodel startRecord];
}
- (void)stopRecord{
    

    [self.fileOutmodel stopRecord];
}

//闪光灯
- (void)FlashState:(FlashState)flashState{
    [self.fileOutmodel FlashState:flashState];
}
//分辨率设置
- (void)setCameraResolution:(resolutionType)type{
    [self.fileOutmodel setCameraResolution:type];
}
//切换摄像头
- (void)cameraPosition:(cameraPosition)position{
    [self.fileOutmodel cameraPosition:position];
}

//聚焦点
- (void)setFocusCursorWithPoint:(CGPoint)point{
    [self.fileOutmodel setFocusCursorWithPoint:point];
}
//设置焦距
- (void)videoScaleAndCropFactor:(float)scale{
    [self.fileOutmodel videoScaleAndCropFactor:scale];
}

// 调节ISO，光感度 0.0-1.0
- (void)cameraBackgroundDidChangeISO:(CGFloat)iso{
    [self.fileOutmodel cameraBackgroundDidChangeISO:iso];
}
//设置帧率
- (void)setFpsWithMaxFps:(int)MaxFps MinFps:(int)MinFps{
    [self.fileOutmodel setFpsWithMaxFps:MaxFps MinFps:MinFps];
}

//横竖屏切换
- (void)setVideoOrientation:(videoOrientation)videoOrientation{
    self.fileOutmodel.videoOrientation = videoOrientation;
}
    
#pragma mark - FileOutModelDelegate

- (void)cameraRecordingTime:(float)time{
    if ([self.delegate respondsToSelector:@selector(cameraRecordingTime:)]) {
        [self.delegate cameraRecordingTime:time];
    }
}

- (void)didStartRecording{
    if ([self.delegate respondsToSelector:@selector(didStartRecording)]) {
        [self.delegate didStartRecording];
    }
}

- (void)didFinishRecording{
    if ([self.delegate respondsToSelector:@selector(didFinishRecording)]) {
        [self.delegate didFinishRecording];
    }
}


@end
