//
//  ViewController.m
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/1/22.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import "MovieFileOutputViewController.h"
#import "fileOutView.h"
#import "VideoListController.h"

@interface MovieFileOutputViewController ()<fileOutViewDelegate>
@property (nonatomic, strong) fileOutView* showView;

@end

@implementation MovieFileOutputViewController

#define kscreenWidth [UIScreen mainScreen].bounds.size.width
#define kscreenheight [UIScreen mainScreen].bounds.size.height
  
-(fileOutView *)showView{
    if (!_showView) {
        _showView = [[fileOutView alloc] initWithFrame:CGRectMake(0, 0, kscreenWidth, kscreenheight)];
        _showView.delegate = self;
    }
    return _showView;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.view addSubview:self.showView];
    
    UIButton* backBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 44, 44)];
    [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setTitle:@"返回" forState:0];
    [self.view addSubview:backBtn];
}


- (void)backAction{
    [self.showView remove];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - fileOutViewDelegate

-(void)jumpVideoList:(NSArray *)videoList{
    VideoListController* Vc = [VideoListController new];
    Vc.videoListArray = videoList;
    [self presentViewController:Vc animated:YES completion:nil];
}

@end
