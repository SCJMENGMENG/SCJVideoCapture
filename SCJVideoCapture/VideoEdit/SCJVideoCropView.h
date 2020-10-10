//
//  SCJVideoCropView.h
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol SCJVideoCropViewDelegate <NSObject>

@optional

/**
 手指移动到的时间
 */
- (void)cutBarDidMovedToTime:(CGFloat)time;

/**
 松开手指
 */
- (void)cutBarTouchesDidEnd;

@end

@class SCJVideoInfoConfig, AVAsset;

@interface SCJVideoCropView : UIView
@property (nonatomic,assign) CGFloat siderTime;
@property (nonatomic, strong) AVAsset *avAsset;
@property (nonatomic,weak) id <SCJVideoCropViewDelegate>delegate;

-(instancetype)initWithFrame:(CGRect)frame videoConfig:(SCJVideoInfoConfig *)config;

-(void)loadThumbnailData;
/**
 更新进度
 
 @param progress 进度
 */
- (void)updateProgressViewWithProgress:(CGFloat)progress;

@end
