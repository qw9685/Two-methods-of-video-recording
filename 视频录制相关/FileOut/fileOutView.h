//
//  fileOutView.h
//  视频录制相关
//
//  Created by 崔畅－MacMini1 on 2018/2/8.
//  Copyright © 2018年 tdy. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol fileOutViewDelegate<NSObject>

- (void)jumpVideoList:(NSArray*)videoList;

@end

@interface fileOutView : UIView

@property (nonatomic,weak) id <fileOutViewDelegate> delegate;

- (void)remove;

@end
