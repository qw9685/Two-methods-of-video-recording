//
//  fileOutView.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/8.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "fileOutView.h"
#import "FileOutManager.h"

@interface fileOutView ()<FileOutManagerDelegate>
    
@property (nonatomic, strong) UIView* bottomView;
@property (nonatomic, strong) UIView* setView;

@property (nonatomic, strong) UIButton* recordBtn;
@property (nonatomic, strong) UIImageView* focusImage;
@property (nonatomic, strong) UILabel* timeLabel;
@property (nonatomic, strong) UIButton* jumpBtn;
@property (nonatomic, strong) FileOutManager* camera;

@property (nonatomic, strong) NSMutableArray<NSURL*>* videoListArray;

@property (nonatomic, strong) NSURL* fileUrl;

@property (nonatomic, strong) CMMotionManager* motionManager;

@end


#define kscreenWidth [UIScreen mainScreen].bounds.size.width
#define kscreenheight [UIScreen mainScreen].bounds.size.height
#define kDoc NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject

@implementation fileOutView

-(NSMutableArray<NSURL *> *)videoListArray{
    if (!_videoListArray) {
        _videoListArray = [NSMutableArray array];
    }
    return _videoListArray;
}

-(CMMotionManager *)motionManager{
    if (!_motionManager) {
        
        _motionManager = [[CMMotionManager alloc] init];
    }
    return _motionManager;
}

-(UIView *)bottomView{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kscreenheight - 100, kscreenWidth, 100)];
        
        _recordBtn = [[UIButton alloc] initWithFrame:CGRectMake((_bottomView.frame.size.width - 60)/2, (_bottomView.frame.size.height - 60)/2, 60, 60)];
        [_recordBtn setImage:[UIImage imageNamed:@"play"] forState:0];
        [_recordBtn addTarget:self action:@selector(recordAction:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_recordBtn];
        
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, _recordBtn.frame.origin.y - 40, kscreenWidth, 20)];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.textColor = [UIColor redColor];
        [_bottomView addSubview:_timeLabel];
        
        _jumpBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, (_bottomView.frame.size.height - 60)/2, 60, 60)];
        _jumpBtn.layer.cornerRadius = _jumpBtn.frame.size.width/2;
        _jumpBtn.hidden = YES;
        _jumpBtn.clipsToBounds = YES;
        [_jumpBtn addTarget:self action:@selector(jumpVideoList) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_jumpBtn];

    }
    return _bottomView;
}

-(UIView *)setView{
    if (!_setView) {
        _setView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kscreenWidth, 64)];
        _setView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5];
        
        UIButton* flashBtn = [[UIButton alloc] initWithFrame:CGRectMake(kscreenWidth - 50 - 20, 20, 44, 44)];
        [flashBtn setImage:[UIImage imageNamed:@"flash_off"] forState:UIControlStateNormal];
        [flashBtn setImage:[UIImage imageNamed:@"flash_on"] forState:UIControlStateSelected];
        [flashBtn addTarget:self action:@selector(flashAction:) forControlEvents:UIControlEventTouchUpInside];
        [_setView addSubview:flashBtn];
        
        UIButton* DirectionBtn = [[UIButton alloc] initWithFrame:CGRectMake(kscreenWidth - 100 - 20, 20, 44, 44)];
        [DirectionBtn setTitle:@"前置" forState:UIControlStateNormal];
        [DirectionBtn addTarget:self action:@selector(changeDirection:) forControlEvents:UIControlEventTouchUpInside];
        [_setView addSubview:DirectionBtn];
        
        UIButton* ResolutionBtn = [[UIButton alloc] initWithFrame:CGRectMake(kscreenWidth - 150 - 20, 20, 44, 44)];
        [ResolutionBtn setTitle:@"720" forState:UIControlStateNormal];
        [ResolutionBtn addTarget:self action:@selector(ResolutionBtnChange:) forControlEvents:UIControlEventTouchUpInside];
        [_setView addSubview:ResolutionBtn];
        
        
    }
    return _setView;
}

-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {

        self.camera = [FileOutManager initCameraWithlayer:self.layer];
        self.camera.delegate = self;
        
        [self addSubview:self.setView];
        [self addSubview:self.bottomView];
        [self addGenstureRecognizer];

        
        [self startMotionManager];
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.camera cameraBackgroundDidChangeISO:0.7];
//            [self.camera setFpsWithMaxFps:240 MinFps:240];
//        });

        
    }
    return self;
}

//检测横竖屏
- (void)startMotionManager{
    
    [self.motionManager startDeviceMotionUpdates];
    self.motionManager.deviceMotionUpdateInterval = 1.0f;
    
    if (self.motionManager.deviceMotionAvailable && self.motionManager.accelerometerAvailable&& self.motionManager.magnetometerAvailable) {
        NSLog(@"Device Motion Available");
        [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                           withHandler: ^(CMDeviceMotion *motion, NSError *error){
                                               [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
                                               
                                           }];
    } else {
        NSLog(@"No device motion on device.");
        self.motionManager = nil;
    }
}

#pragma mark - 屏幕旋转
- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    
    if(self.camera.isRecording)return;
    
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;

    if (fabs(y) >= fabs(x))
    {
        // UIDeviceOrientationPortraitUpsideDown || UIDeviceOrientationPortrait;
        self.transform = CGAffineTransformIdentity;
        [self.camera setVideoOrientation:VideoOrientationPortrait];
    }else{

        if (x >= 0){
//             UIDeviceOrientationLandscapeRight;
            self.recordBtn.transform = CGAffineTransformMakeRotation(-M_PI_2);
            self.timeLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
            [self.camera setVideoOrientation:VideoOrientationLandscapeRight];
        }else{

//             UIDeviceOrientationLandscapeLeft;
            self.recordBtn.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.timeLabel.transform = CGAffineTransformMakeRotation(M_PI_2);
            [self.camera setVideoOrientation:VideoOrientationLandscapeLeft];
        }
    }
}

- (void)remove{
    [self.camera stopRunning];
    [self removeFromSuperview];
}

/**
 *  添加点按手势，点按时聚焦
 */

-(void)addGenstureRecognizer{
    
    self.focusImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"对焦"]];
    self.focusImage.hidden = YES;
    [self addSubview:self.focusImage];
    
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    //    tapGesture.numberOfTapsRequired = 2;
    [self addGestureRecognizer:tapGesture];
    UIPinchGestureRecognizer *doubleTapGesture=[[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    doubleTapGesture.delaysTouchesBegan = YES;
    
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    [self addGestureRecognizer:doubleTapGesture];
    
}

#pragma mark - 录制
- (void)recordAction:(UIButton*)sender{
    
    if (self.camera.isRecording) {
        [self stopRecord];
    }else{
        [self startRecord];
    }
}

- (void)stopRecord{
    [self.recordBtn setImage:[UIImage imageNamed:@"play"] forState:0];
    self.jumpBtn.hidden = NO;
    [self.camera stopRecord];
}

- (void)startRecord{
    self.fileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%lu.mp4",kDoc,(unsigned long)self.videoListArray.count]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.fileUrl.path]) {
        [[NSFileManager defaultManager] removeItemAtURL:self.fileUrl error:nil];
    }
    self.camera.fileUrl = self.fileUrl;
    [self.videoListArray addObject:self.fileUrl];
    [self.recordBtn setImage:[UIImage imageNamed:@"stop"] forState:0];
    self.jumpBtn.hidden = YES;
    [self.camera startRecord];
}

#pragma mark - 跳转
- (void)jumpVideoList{
    
    if ([self.delegate respondsToSelector:@selector(jumpVideoList:)]) {
        [self.delegate jumpVideoList:self.videoListArray];
    }
}

- (void)flashAction:(UIButton*)sender{
    
    if (self.camera.isRecording) {
        return;
    }
    
    if (sender.selected) {
        [self.camera FlashState:FlashClose];
    }else{
        [self.camera FlashState:FlashOpen];
    }
    sender.selected = !sender.selected;
}

- (void)changeDirection:(UIButton*)sender{
    
    if (self.camera.isRecording) {
        return;
    }
    
    if (!sender.selected) {
        [self.camera cameraPosition:PositionPositionFront];
        [sender setTitle:@"前置" forState:0];
        
    }else{
        [self.camera cameraPosition:PositionPositionBack];
        [sender setTitle:@"后置" forState:0];
    }
    sender.selected = !sender.selected;
}

- (void)ResolutionBtnChange:(UIButton*)sender{
    if (self.camera.isRecording) {
        return;
    }
    
    if (!sender.selected) {
        [self.camera setCameraResolution:resolution_1920x1080];
        [sender setTitle:@"1080" forState:0];
    }else{
        [self.camera setCameraResolution:resolution_1280x720];
        [sender setTitle:@"720" forState:0];
    }
    
    sender.selected = !sender.selected;
}

- (void)tapScreen:(UIGestureRecognizer*)ges{
    
    CGPoint point = [ges locationInView:self];
    self.focusImage.bounds = CGRectMake(0, 0, 70, 70);
    self.focusImage.center = point;
    
    self.focusImage.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.focusImage.bounds = CGRectMake(0, 0, 50, 50);
    } completion:^(BOOL finished) {
        self.focusImage.hidden = YES;
        [self.camera setFocusCursorWithPoint:point];
    }];
}

- (void)doubleTap:(UIPinchGestureRecognizer*)ges{
    
    CGFloat scale = ges.scale;
    ges.scale = MAX(1.0, scale);
    
    if (scale < 1.0f || scale > 3.0)
    {
        return;
    }
    
    NSLog(@"捏合%f",scale);
    [self.camera videoScaleAndCropFactor:scale];
}

#pragma mark - cameraManagerDelegate
-(void)cameraRecordingTime:(float)time{
    
    self.timeLabel.text = [self convertTime:time];
}

-(void)didStartRecording{
    self.timeLabel.hidden = NO;
}

-(void)didFinishRecording{
    self.timeLabel.hidden = YES;
    
     [self.jumpBtn setImage:[self thumbnailImageForVideo:self.fileUrl atTime:1] forState:0];
}

- (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetImageGenerator =[[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetImageGenerator.appliesPreferredTrackTransform = YES;
    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *thumbnailImageGenerationError = nil;
    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)actualTime:NULL error:&thumbnailImageGenerationError];
    
    if(!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@",thumbnailImageGenerationError);
    
    UIImage*thumbnailImage = thumbnailImageRef ? [[UIImage alloc]initWithCGImage: thumbnailImageRef] : nil;
    
    return thumbnailImage;
}

//转换时间
- (NSString*)convertTime:(float)sec{
    
    NSInteger mi = 60;
    NSInteger hh = mi * 60;
    
    long hour = sec / hh;
    long minute = (sec - hour * hh) / mi;
    long second = (sec - hour * hh - minute * mi);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hour,minute,second];
}

@end

