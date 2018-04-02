//
//  FileOutModel.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/8.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "FileOutModel.h"


@interface FileOutModel ()<AVCaptureFileOutputRecordingDelegate>{
    NSTimer* timer;//监听录制时间
}

@property (nonatomic, strong) CALayer* camera_layer;//展示的layer

/// 负责输入和输出设备之间的数据传递
@property (nonatomic, strong) AVCaptureSession *captureSession;
/// 负责从AVCaptureDevice获得视频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
/// 负责从AVCaptureDevice获得音频输入流
@property (nonatomic, strong) AVCaptureDeviceInput *audioCaptureDeviceInput;
/// 视频输出流
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureMovieFileOutput;
/// 相机拍摄预览图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
// 根据设备输出获得连接
@property (nonatomic, strong) AVCaptureConnection *captureConnection;

//录制设置信息
@property (nonatomic, strong) AVCaptureDeviceFormat *defaultFormat;
@property (nonatomic, assign) CMTime defaultMinFrameDuration;
@property (nonatomic, assign) CMTime defaultMaxFrameDuration;
@property (nonatomic, strong) AVCaptureSessionPreset currentSessionPreset;//当前分辨率

@end;

@implementation FileOutModel

-(BOOL)isRecording{
    return [self.captureMovieFileOutput isRecording];
}

-(void)setStabilizedModel:(BOOL)stabilizedModel{
    _stabilizedModel = stabilizedModel;
    
    AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    NSLog(@"change captureConnection: %@", captureConnection);
    AVCaptureDevice *videoDevice = self.captureDeviceInput.device;
    
    AVCaptureVideoStabilizationMode model = stabilizedModel?AVCaptureVideoStabilizationModeCinematic:AVCaptureVideoStabilizationModeOff;
    
    NSLog(@"set format: %@", videoDevice.activeFormat);
    if ([videoDevice.activeFormat isVideoStabilizationModeSupported:model]) {
        captureConnection.preferredVideoStabilizationMode = model;
    }
}

+ (FileOutModel*)initCameraWithlayer:(CALayer*)layer{
    
    FileOutModel* model = [[FileOutModel alloc]init];
    model.camera_layer = layer;
    
    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
    [model initCaptureSession];
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"Linked in %f ms", linkTime *1000.0);

    return model;
}

- (void)initCaptureSession{
    // 创建AVCaptureSession
    self.captureSession = [[AVCaptureSession alloc] init];
    // 默认设置
    self.resolutionType = resolution_1280x720;
    self.FlashState = FlashClose;
    self.cameraPosition = PositionPositionBack;
    
    self.currentSessionPreset = AVCaptureSessionPreset1280x720;
    if ([self.captureSession canSetSessionPreset:self.currentSessionPreset]){
        self.captureSession.sessionPreset = self.currentSessionPreset;
    }
    
    NSCAssert([self.captureSession canSetSessionPreset:self.currentSessionPreset], @"cannot set 1280x720");
    
    // 获取摄像设备
    AVCaptureDevice *videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];
    
    NSCAssert(videoCaptureDevice, @"videoCaptureDevice == nil");
    
    // 获取视频输入流
    NSError *error = nil;
    self.captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    
    if (error) {
        NSLog(@"======%@",error);
    }
    
    // 获取录音设备
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    
    // 获取音频输入流
    self.audioCaptureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (error) {
        NSLog(@"======%@",error);
    }
    
    // 将视频和音频输入添加到AVCaptureSession
    if ([_captureSession canAddInput:_captureDeviceInput] && [_captureSession canAddInput:_audioCaptureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:_audioCaptureDeviceInput];
    }
    
    // 创建输出流
    _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    //    _captureMovieFileOutput.maxRecordedDuration1 = CMTimeMake(10, 1);//设置最大录制时长 // maxRecordedFileSize
    
    // 将输出流添加到AVCaptureSession
    if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
        [_captureSession addOutput:_captureMovieFileOutput];
        // 根据设备输出获得连接
        self.captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        
        // 判断是否支持光学防抖
        if ([videoCaptureDevice.activeFormat isVideoStabilizationModeSupported:AVCaptureVideoStabilizationModeCinematic]) {
            // 如果支持防抖就打开防抖
            self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeCinematic;
        }
        
        for ( AVFrameRateRange *range in videoCaptureDevice.activeFormat.videoSupportedFrameRateRanges ) {
            NSLog(@"=====当前支持的bit:%@",range);
            
        }
        
        videoCaptureDevice.activeVideoMinFrameDuration = CMTimeMake(1,30);
        videoCaptureDevice.activeVideoMaxFrameDuration = CMTimeMake(1,30);

    }
    
    // 保存默认的AVCaptureDeviceFormat
    _defaultFormat = videoCaptureDevice.activeFormat;
    _defaultMinFrameDuration = videoCaptureDevice.activeVideoMinFrameDuration;
    _defaultMaxFrameDuration = videoCaptureDevice.activeVideoMaxFrameDuration;
    
    // 创建预览图层
    _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    _captureVideoPreviewLayer.frame = self.camera_layer.bounds;
    
    [self.camera_layer addSublayer:_captureVideoPreviewLayer];
    
    // 开始捕获 防止卡顿 开线程处理
    dispatch_async(dispatch_queue_create(0, 0), ^{
        [self.captureSession startRunning];
    });
}

- (void)startRunning{
    // 开始捕获 防止卡顿 开线程处理
    dispatch_async(dispatch_queue_create(0, 0), ^{
        [self.captureSession startRunning];
    });
}

- (void)stopRunning{
    dispatch_async(dispatch_queue_create(0, 0), ^{
        if ([self.captureSession isRunning]) {
            [self.captureSession stopRunning];
        }
    });
}

/// 获取摄像头设备
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            if ([device supportsAVCaptureSessionPreset:self.currentSessionPreset]){
                return device;
            }else{
                return nil;
            }
        }
    }
    return nil;
}

//改变设备属性前一定要首先调用lockForConfiguration方法加锁,调用完之后使用unlockForConfiguration方法解锁.
-(void)changeDevicePropertySafety:(void (^)(AVCaptureDevice *captureDevice))propertyChange{
    
    //也可以直接用_videoDevice,但是下面这种更好
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    
    BOOL lockAcquired = [captureDevice lockForConfiguration:&error];
    if (!lockAcquired) {
        NSLog(@"锁定设备过程error，错误信息：%@",error.localizedDescription);
    }else{
        [_captureSession beginConfiguration];
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
        [_captureSession commitConfiguration];
    }
}

- (void)startRecord{
    
    // 根据连接取得设备输出的数据
    if (!self.isRecording) {
        
        [self setVideoOrientation];
        [self.captureMovieFileOutput startRecordingToOutputFileURL:self.fileUrl recordingDelegate:self];
    }
}
    
//横竖屏切换
- (void)setVideoOrientation{
    AVCaptureConnection *captureConnection = nil;
    for ( AVCaptureConnection *connection in [self.captureMovieFileOutput connections] )
    {
        for ( AVCaptureInputPort *port in [connection inputPorts] )
        {
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                captureConnection = connection;
            }
        }
    }
    
    if([captureConnection isVideoOrientationSupported]) // **Here it is, its always false**
    {
        switch (self.videoOrientation) {
            case 0:
            captureConnection.videoOrientation=AVCaptureVideoOrientationPortrait;
            break;
            case 1:
            captureConnection.videoOrientation=AVCaptureVideoOrientationLandscapeRight;
            break;
            case 2:
            captureConnection.videoOrientation=AVCaptureVideoOrientationLandscapeLeft;
            break;
            default:
            break;
        }
    }
}
    
- (void)stopRecord{
    
    if (self.isRecording) {
        [self.captureMovieFileOutput stopRecording];
    }
}

- (void)startTimer{
    [self removeTimer];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
        if ([self.delegate respondsToSelector:@selector(cameraRecordingTime:)]) {
            [self.delegate cameraRecordingTime:CMTimeGetSeconds(self.captureMovieFileOutput.recordedDuration)];
        }
    }];
}

- (void)removeTimer{
    [timer invalidate];
    timer = nil;
}
#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections{
    
    if ([self.delegate respondsToSelector:@selector(didStartRecording)]) {
        [self.delegate didStartRecording];
    }
    [self startTimer];
}

- (void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(nullable NSError *)error{
    
    if ([self.delegate respondsToSelector:@selector(didFinishRecording)]) {
        [self.delegate didFinishRecording];
    }
    [self removeTimer];
}

#pragma mark - 闪光灯
- (void)FlashState:(FlashState)flashState{
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        AVCaptureTorchMode TorchMode;
        switch (flashState) {
            case 0:
                TorchMode = AVCaptureTorchModeOff;
                break;
            case 1:
                TorchMode = AVCaptureTorchModeOn;
                break;
            case 2:
                TorchMode = AVCaptureTorchModeAuto;
                break;
            default:
                break;
        }
        
        if ([captureDevice isTorchModeSupported:TorchMode]){
            self.FlashState = FlashClose;
            [captureDevice setTorchMode:TorchMode];
        }else{
            NSLog(@"====FlashState----NOSupported");
        }
    }];
}

//聚焦点
- (void)setFocusCursorWithPoint:(CGPoint)point{
    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:cameraPoint];
        }
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:cameraPoint];
        }
    }];
}

//设置焦距
- (void)videoScaleAndCropFactor:(float)scale{
    
    AVCaptureDevice *captureDevice= [self.captureDeviceInput device];
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        [captureDevice rampToVideoZoomFactor:scale withRate:10];
    }else{
        // Handle the error appropriately.
        NSLog(@"===%@",error);
    }
    
}

//切换摄像头
- (void)cameraPosition:(cameraPosition)position{
    
    AVCaptureDevice *videoCaptureDevice;
    switch (position) {
        case 0:
            videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionUnspecified];
            break;
        case 1:
            videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];;
            break;
        case 2:
            videoCaptureDevice = [self getCameraDeviceWithPosition:AVCaptureDevicePositionFront];;
            break;
        default:
            break;
    }
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
        
        if (newVideoInput != nil) {
            //必选先 remove 才能询问 canAdd
            [_captureSession removeInput:self.captureDeviceInput];
            if ([_captureSession canAddInput:newVideoInput]) {
                [_captureSession addInput:newVideoInput];
                self.captureDeviceInput = newVideoInput;
                self.cameraPosition = position;
            }else{
//                [_captureSession addInput:self.captureDeviceInput];
                NSLog(@"切换前/后摄像头失败, error = %@", error);
            }
            
        } else if (error) {
            NSLog(@"切换前/后摄像头失败, error = %@", error);
           
        }
    }];
}

//分辨率设置
- (void)setCameraResolution:(resolutionType)type{
    
    switch (type) {
        case 0:
            self.currentSessionPreset = AVCaptureSessionPreset1280x720;
            break;
        case 1:
            self.currentSessionPreset = AVCaptureSessionPreset1920x1080;
            break;
        case 2:
            self.currentSessionPreset = AVCaptureSessionPreset3840x2160;
            break;
            
        default:
            break;
    }
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
       
        if ([self.captureSession canSetSessionPreset:self.currentSessionPreset]){
            self.captureSession.sessionPreset = self.currentSessionPreset;
            self.resolutionType = type;
        }else{
            NSLog(@"====切换分辨率失败");
        }
    }];
}

// 调节ISO，光感度 0.0-1.0
- (void)cameraBackgroundDidChangeISO:(CGFloat)iso {
    
    [self changeDevicePropertySafety:^(AVCaptureDevice *captureDevice) {
        CGFloat minISO = captureDevice.activeFormat.minISO;
        CGFloat maxISO = captureDevice.activeFormat.maxISO;
        CGFloat currentISO = (maxISO - minISO) * iso + minISO;
        [captureDevice setExposureModeCustomWithDuration:AVCaptureExposureDurationCurrent ISO:currentISO completionHandler:nil];
        [captureDevice unlockForConfiguration];
    }];
    
}

//Tips: 在切换摄像头的时候Stop Seesion,然后重新设置FrameRate，最后重新Run Seesion。
- (void)setFpsWithMaxFps:(int)MaxFps MinFps:(int)MinFps{

    [self.captureSession stopRunning];

    AVCaptureDevice *videoDevice = self.captureDeviceInput.device;
    AVCaptureDeviceFormat *selectedFormat = nil;
    int32_t maxWidth = 0;
    AVFrameRateRange *frameRateRange = nil;
    for (AVCaptureDeviceFormat *format in [videoDevice formats]) {
        for (AVFrameRateRange *range in format.videoSupportedFrameRateRanges) {
            CMFormatDescriptionRef desc = format.formatDescription;
            CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(desc);
            int32_t width = dimensions.width;
            if (range.minFrameRate <= MinFps && MaxFps <= range.maxFrameRate && width >= maxWidth) {
                selectedFormat = format;
                frameRateRange = range;
                maxWidth = width;
            }
        }
    }
    if (selectedFormat) {
        if ([videoDevice lockForConfiguration:nil]) {
            NSLog(@"selected format: %@", selectedFormat);
            videoDevice.activeFormat = selectedFormat;
            videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, (int32_t)MinFps);
            videoDevice.activeVideoMaxFrameDuration = CMTimeMake(1, (int32_t)MaxFps);
            [videoDevice unlockForConfiguration];
        }
    }else{
        NSLog(@"===设置帧率失败");
    }
    [self.captureSession startRunning];
}


//调节视频的速度
//慢动作拍摄的时候要调节摄像头的捕捉频率，快速的时候直接调节视频速度就可以了。
//慢动作下拍摄的视频视频的播放时长还是实际拍摄的时间，这里根据设置的慢速倍率，把视频的时长拉长。

// 处理速度视频
//- (void)setSpeedWithVideo:(NSDictionary *)video completed:(void(^)())completed {
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        NSLog(@"video set thread: %@", [NSThread currentThread]);
//        // 获取视频
//        AVURLAsset* videoAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:video[kMoviePath]] options:nil];
//        // 视频混合
//        AVMutableComposition* mixComposition = [AVMutableComposition composition];
//        // 视频轨道
//        AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
//        // 音频轨道
//        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
//
//        // 视频的方向
//        CGAffineTransform videoTransform = [videoAsset tracksWithMediaType:AVMediaTypeVideo].lastObject.preferredTransform;
//        if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
//            NSLog(@"垂直拍摄");
//            videoTransform = CGAffineTransformMakeRotation(M_PI_2);
//        }else if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
//            NSLog(@"倒立拍摄");
//            videoTransform = CGAffineTransformMakeRotation(-M_PI_2);
//        }else if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
//            NSLog(@"Home键右侧水平拍摄");
//            videoTransform = CGAffineTransformMakeRotation(0);
//        }else if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
//            NSLog(@"Home键左侧水平拍摄");
//            videoTransform = CGAffineTransformMakeRotation(M_PI);
//        }
//        // 根据视频的方向同步视频轨道方向
//        compositionVideoTrack.preferredTransform = videoTransform;
//        compositionVideoTrack.naturalTimeScale = 600;
//
//        // 插入视频轨道
//        [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject] atTime:kCMTimeZero error:nil];
//        // 插入音频轨道
//        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject] atTime:kCMTimeZero error:nil];
//
//        // 适配视频速度比率
//        CGFloat scale = 1.0;
//        if([video[kMovieSpeed] isEqualToString:kMovieSpeed_Fast]){
//            scale = 0.2f;  // 快速 x5
//        } else if ([video[kMovieSpeed] isEqualToString:kMovieSpeed_Slow]) {
//            scale = 4.0f;  // 慢速 x4
//        }
//
//        // 根据速度比率调节音频和视频
//        [compositionVideoTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) toDuration:CMTimeMake(videoAsset.duration.value * scale , videoAsset.duration.timescale)];
//        [compositionAudioTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(videoAsset.duration.value, videoAsset.duration.timescale)) toDuration:CMTimeMake(videoAsset.duration.value * scale, videoAsset.duration.timescale)];
//
//        // 配置导出
//        AVAssetExportSession* _assetExport = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset1280x720];
//        // 导出视频的临时保存路径
//        NSString *exportPath = [kCachePath stringByAppendingPathComponent:[self movieName]];
//        NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
//
//        // 导出视频的格式 .MOV
//        _assetExport.outputFileType = AVFileTypeQuickTimeMovie;
//        _assetExport.outputURL = exportUrl;
//        _assetExport.shouldOptimizeForNetworkUse = YES;
//
//        // 导出视频
//        [_assetExport exportAsynchronouslyWithCompletionHandler:
//         ^(void ) {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 [_processedVideoPaths addObject:exportPath];
//                 // 将导出的视频保存到相册
//                 ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//                 if (![library videoAtPathIsCompatibleWithSavedPhotosAlbum:[NSURL URLWithString:exportPath]]){
//                     NSLog(@"cache can't write");
//                     completed();
//                     return;
//                 }
//                 [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:exportPath] completionBlock:^(NSURL *assetURL, NSError *error) {
//                     if (error) {
//                         completed();
//                         NSLog(@"cache write error");
//                     } else {
//                         completed();
//                         NSLog(@"cache write success");
//                     }
//                 }];
//             });
//         }];
//    });
//}


@end
