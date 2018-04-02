//
//  fileOutView.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/8.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "assetWriterView.h"
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import "assetWriterModel.h"

@interface assetWriterView ()<assetWriterModelDelegate>

@property (nonatomic, strong) UIView* bottomView;
@property (nonatomic, strong) UIButton* recordBtn;
@property (nonatomic, strong) UILabel* timeLabel;
@property (nonatomic, strong) NSMutableArray<NSURL*>* videoListArray;
@property (nonatomic, strong) NSURL* fileUrl;
@property (strong, nonatomic) assetWriterModel *cameraModel;

@end

#define kscreenWidth [UIScreen mainScreen].bounds.size.width
#define kscreenheight [UIScreen mainScreen].bounds.size.height
#define kDoc NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject

@implementation assetWriterView

- (assetWriterModel *)cameraModel {
    if (_cameraModel == nil) {
        _cameraModel = [[assetWriterModel alloc] init];
        _cameraModel.delegate =  self;
    }
    return _cameraModel;
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
        
    }
    return _bottomView;
}

-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        [self addSubview:self.bottomView];
        
        self.cameraModel = [assetWriterModel initCameraWithlayer:self.layer];
        NSString* path = [kDoc stringByAppendingString:@"/1.mov"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        self.cameraModel.videoPath = path;
        self.cameraModel.maxRecordTime = 5;
        self.cameraModel.videoHeight = 1280;
        self.cameraModel.videoWeight = 720;
        self.cameraModel.frameRate = 60;
        self.cameraModel.videoRate = 8*1024.0*1024;
        self.cameraModel.channels = 2;
        self.cameraModel.samplerate = 44100;
        self.cameraModel.audioBitRate = 64000;
        
    }
    return self;
}

- (void)remove{
    [self removeFromSuperview];
    [self.cameraModel shutdown];
}

#pragma mark - 录制
- (void)recordAction:(UIButton*)sender{
    
    if (_cameraModel.isCapturing) {
        if (_cameraModel.isPaused) {
            [_cameraModel resumeCapture];
        }else{
            [_cameraModel pauseCapture];
            [self.recordBtn setImage:[UIImage imageNamed:@"play"] forState:0];
        }
    }else{
        [_cameraModel startCapture];
    }
}

#pragma mark - ================ assetWriterModelDelegate ================

-(void)recordProgress:(CGFloat)progress{
    self.timeLabel.text = [NSString stringWithFormat:@"%f",progress];
}

@end


