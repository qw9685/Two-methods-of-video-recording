//
//  assetWriterModel.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/3/1.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "assetWriterModel.h"
#import <UIKit/UIKit.h>
#import "assetWriterEncode.h"
#import <Photos/Photos.h>

@interface assetWriterModel ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate, CAAnimationDelegate>
    {
        CMTime _timeOffset;//录制的偏移CMTime
        CMTime _lastVideo;//记录上一次视频数据文件的CMTime
        CMTime _lastAudio;//记录上一次音频数据文件的CMTime
    }

@property (strong, nonatomic) assetWriterEncode           *recordEncoder;//录制编码
@property (strong, nonatomic) AVCaptureSession           *recordSession;//捕获视频的会话
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;//捕获到的视频呈现的layer
@property (strong, nonatomic) AVCaptureDeviceInput       *backCameraInput;//后置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput       *audioMicInput;//麦克风输入
@property (copy  , nonatomic) dispatch_queue_t           captureQueue;//录制的队列
@property (strong, nonatomic) AVCaptureConnection        *audioConnection;//音频录制连接
@property (strong, nonatomic) AVCaptureConnection        *videoConnection;//视频录制连接
@property (strong, nonatomic) AVCaptureVideoDataOutput   *videoOutput;//视频输出
@property (strong, nonatomic) AVCaptureAudioDataOutput   *audioOutput;//音频输出
@property (atomic, assign) BOOL isCapturing;//正在录制
@property (atomic, assign) BOOL isPaused;//是否暂停
@property (atomic, assign) BOOL discont;//是否中断
@property (atomic, assign) CMTime startTime;//开始录制的时间
@property (atomic, assign) CGFloat currentRecordTime;//当前录制时间

@end

@implementation assetWriterModel

+ (assetWriterModel*)initCameraWithlayer:(CALayer*)layer{
    assetWriterModel* model = [[assetWriterModel alloc] init];
    
    AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:model.recordSession];
    //设置比例
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [layer addSublayer:preview];
    model.previewLayer = preview;
    [model startUp];
    
    return model;
}

//初始化编码器
-(assetWriterEncode *)recordEncoder{
    if (!_recordEncoder) {
       _recordEncoder = [assetWriterEncode encoderForPath:self.videoPath Height:_videoHeight width:_videoWeight videoRate:_frameRate BitRate:_videoRate channels:_channels samples:_samplerate audioBitRate:_audioBitRate];
    }
    return _recordEncoder;
}

- (void)sessionRunning{
    dispatch_async(dispatch_queue_create(0, 0), ^{
        [self.recordSession startRunning];
    });
}

- (void)sessionStop{
    dispatch_async(dispatch_queue_create(0, 0), ^{
        [self.recordSession stopRunning];
    });
}

//初始化录制
- (void)startUp {
    self.startTime = CMTimeMake(0, 0);
    self.isCapturing = NO;
    self.isPaused = NO;
    self.discont = NO;
    
    [self sessionRunning];
}

//移除录制
- (void)shutdown {
    _startTime = CMTimeMake(0, 0);
    [self sessionStop];
    [_recordEncoder finishWithCompletionHandler:^{
        
    }];
}

//开始录制
- (void) startCapture {
    if (!self.isCapturing) {
        self.recordEncoder = nil;
        self.isPaused = NO;
        self.discont = NO;
        _timeOffset = CMTimeMake(0, 0);
        self.isCapturing = YES;
    }
}
//暂停录制
- (void) pauseCapture {
    if (self.isCapturing) {
        self.isPaused = YES;
        self.discont = YES;
    }
}

//继续录制
- (void) resumeCapture {
    if (self.isPaused) {
        self.isPaused = NO;
    }
}

//停止录制
- (void) stopCaptureHandler:(void (^)(UIImage *movieImage))handler {
    if (self.isCapturing) {
        self.isCapturing = NO;
        dispatch_async(_captureQueue, ^{
            [self.recordEncoder finishWithCompletionHandler:^{
                if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
                    });
                }
                self.isCapturing = NO;
                self.recordEncoder = nil;
                self.startTime = CMTimeMake(0, 0);
                self.currentRecordTime = 0;
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:self.videoPath]];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    NSLog(@"保存成功");
                }];
                
            }];
        });
    }
}

#pragma mark - set、get方法
//捕获视频的会话
- (AVCaptureSession *)recordSession {
    if (_recordSession == nil) {
        _recordSession = [[AVCaptureSession alloc] init];
        //添加后置摄像头的输出
        if ([_recordSession canAddInput:self.backCameraInput]) {
            [_recordSession addInput:self.backCameraInput];
        }
        //添加后置麦克风的输出
        if ([_recordSession canAddInput:self.audioMicInput]) {
            [_recordSession addInput:self.audioMicInput];
        }
        //添加视频输出
        if ([_recordSession canAddOutput:self.videoOutput]) {
            [_recordSession addOutput:self.videoOutput];
        }
        //添加音频输出
        if ([_recordSession canAddOutput:self.audioOutput]) {
            [_recordSession addOutput:self.audioOutput];
        }
        //设置视频录制的方向
        self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return _recordSession;
}

//摄像头输入
- (AVCaptureDeviceInput *)backCameraInput {
    if (_backCameraInput == nil) {
        NSError *error;
        _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        if (error) {
            NSLog(@"获取后置摄像头失败");
        }
    }
    return _backCameraInput;
}

//麦克风输入
- (AVCaptureDeviceInput *)audioMicInput {
    if (_audioMicInput == nil) {
        AVCaptureDevice *mic = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        NSError *error;
        _audioMicInput = [AVCaptureDeviceInput deviceInputWithDevice:mic error:&error];
        if (error) {
            NSLog(@"获取麦克风失败");
        }
    }
    return _audioMicInput;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoOutput {
    if (_videoOutput == nil) {
        _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
        NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                        nil];
        _videoOutput.videoSettings = setcapSettings;
    }
    return _videoOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioOutput {
    if (_audioOutput == nil) {
        _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    }
    return _audioOutput;
}

//视频连接
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

//音频连接
- (AVCaptureConnection *)audioConnection {
    if (_audioConnection == nil) {
        _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    }
    return _audioConnection;
}

//录制的队列
- (dispatch_queue_t)captureQueue {
    if (_captureQueue == nil) {
        _captureQueue = dispatch_queue_create(0, 0);
    }
    return _captureQueue;
}

- (void)animationDidStart:(CAAnimation *)anim {
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self sessionRunning];
}

#pragma mark - 视频相关
//返回后置摄像头
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    //返回和视频录制相关的所有默认设备
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    //遍历这些设备返回跟position相关的设备
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

#pragma mark - 写入数据
- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL isVideo = YES;
    @synchronized(self) {
        if (!self.isCapturing  || self.isPaused) {
            return;
        }
        if (captureOutput != self.videoOutput) {
            //输出音频流
            isVideo = NO;
        }
        //判断是否中断录制过
        if (self.discont) {
            if (isVideo) {
                return;
            }
            self.discont = NO;
            // 当前buffer起点时间
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = isVideo ? _lastVideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                }else {
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastVideo.flags = 0;
            _lastAudio.flags = 0;
        }
        // 增加sampleBuffer的引用计时,这样我们可以释放这个或修改这个数据，防止在修改时被释放
        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
            //根据得到的timeOffset调整
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        // 记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (isVideo) {
            _lastVideo = pts;
        }else {
            _lastAudio = pts;
        }
    }
    CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (self.startTime.value == 0) {
        self.startTime = dur;
    }
    CMTime sub = CMTimeSubtract(dur, self.startTime);
    self.currentRecordTime = CMTimeGetSeconds(sub);
    if (self.currentRecordTime > self.maxRecordTime) {
        if (self.currentRecordTime - self.maxRecordTime < 0.1) {
            [self stopCaptureHandler:^(UIImage *movieImage) {
                
            }];
        }
        return;
    }
    if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
        });
    }
    // 进行数据编码
    [self.recordEncoder encodeFrame:sampleBuffer isVideo:isVideo];
    CFRelease(sampleBuffer);
}

//调整媒体数据的时间
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

@end
