//
//  SCJVideoEditController.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoEditController.h"
#import "SCJVideoCropView.h"
#import "SCJVideoPlayView.h"
#import "SCJVideoManager.h"
#import "UIImage+SCJ.h"
#import "UIView+SCJ.h"

#import <AVFoundation/AVFoundation.h>
#import <TZImageManager.h>
#import <FDFullscreenPopGesture/UINavigationController+FDFullscreenPopGesture.h>

#define kStartTime  0
#define kEndTime  15
#define kMaxDuration  15
#define kMinDuration  1

#define kisiPhoneX   \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);})

#define kScreenWidth  [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kIPhoneInditorBottomMargin (kisiPhoneX ? 34.0f : 0)
#define kNavHeight  (kisiPhoneX ? 88 : 64)

@interface SCJVideoEditController ()<SCJVideoCropViewDelegate,SCJVideoPlayViewDelegate>
{
    SCJVideoInfoConfig *_videoConfig;
}

@property (nonatomic, strong) SCJVideoPlayView *playView;
@property (nonatomic, strong) SCJVideoCropView *cropView;
@property (nonatomic, strong) id timeObserver;

@property (nonatomic, assign) BOOL isEntering;
@property (nonatomic, strong) SCJVideoManager *videoManager;
@end

@implementation SCJVideoEditController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor blackColor]] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    
    self.navigationController.fd_fullscreenPopGestureRecognizer.enabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    
    self.navigationController.fd_fullscreenPopGestureRecognizer.enabled = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    [self initUI];
}

//移除时间管理
- (void)removeTimeObserver {
    if (self.timeObserver){
        [self.playView.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

- (void)initUI {
    self.videoManager = [[SCJVideoManager alloc] init];
    
    UIImage* itemImage= [UIImage imageNamed:@"common_back_white"];
    itemImage = [itemImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:itemImage style:UIBarButtonItemStylePlain target:self action:@selector(leftItemClick)];
    self.navigationItem.leftBarButtonItem = leftItem;
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 34)];
    UIButton *rightBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 7, 60, 25)];
    [rightBtn setCornerRadius:12.5];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    rightBtn.backgroundColor = [UIColor colorWithRed:82/255.0 green:122/255.0 blue:255/255.0 alpha:1];
    [rightBtn setTitle:@"确定" forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(rightItemClick) forControlEvents:UIControlEventTouchUpInside];
    [rightView addSubview:rightBtn];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightView];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    [self setConfig];
    [self.view addSubview:self.playView];
    [self.view addSubview:self.cropView];
    
    self.playView.videoConfig = _videoConfig;
    self.playView.playerItem.forwardPlaybackEndTime = CMTimeMake(_videoConfig.endTime * 1000, 1000);
}

-(void)setConfig{
    SCJVideoInfoConfig *config = [[SCJVideoInfoConfig alloc]init];
    config.startTime=kStartTime;
    config.endTime=kEndTime;
    config.minDuration=kMinDuration;
    config.maxDuration=kMaxDuration;
    config.sourceDuration =[self avAssetVideoTrackDuration:self.videoModel.avAsset];
    _videoConfig = config;
}

- (CGFloat)avAssetVideoTrackDuration:(AVAsset *)asset {
    
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count) {
        AVAssetTrack *track = videoTracks[0];
        return CMTimeGetSeconds(CMTimeRangeGetEnd(track.timeRange));
    }
    
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count) {
        AVAssetTrack *track = audioTracks[0];
        return CMTimeGetSeconds(CMTimeRangeGetEnd(track.timeRange));
    }
    
    return -1;
}

//返回
- (void)leftItemClick {
    [self removeTimeObserver];
    [self.navigationController popViewControllerAnimated:YES];
}

//确定
- (void)rightItemClick {
    __weak __typeof(&*self)weakSelf = self;
    
    if (self.isEntering) {
        return;
    }
    self.isEntering = YES;
    
    [self.videoManager cutVideoWithAVAsset:self.playView.playerItem.asset startTime:_videoConfig.startTime endTime:_videoConfig.endTime completion:^(UIImage *firstImg, NSString *filePath) {
        NSLog(@"firstImg：%@,fileName：%@",firstImg,filePath);
        
        NSString *fileName = [[filePath lastPathComponent] componentsSeparatedByString:@"."][0];
        NSString *fileId = @"123456";
        
        NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
        dicM[@"videoData"] = [NSString stringWithFormat:@"%@;%@;%d;%f;%@",filePath,fileName,0,self->_videoConfig.endTime -self->_videoConfig.startTime,fileId];
        
        NSLog(@"剪切并保存到相册");
        
        //停止播放
        [weakSelf.playView.player pause];
        [weakSelf removeTimeObserver];
        [weakSelf dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark  手指滚动
- (void)cutBarDidMovedToTime:(CGFloat)time {
    if (time<=0) {
        return;
    }
    if (self.playView.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.playView.player seekToTime:CMTimeMake(time * 1000, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        if (self.playView.playerStatus == CropPlayerStatusPlaying) {
            [self.playView.player pause];
            self.playView.playerStatus = CropPlayerStatusPlayingBeforeSeek;
            if (_timeObserver){
                [self.playView.player removeTimeObserver:_timeObserver];
                _timeObserver=nil;
            }
        }
    }
}

#pragma mark 手指滚动结束
- (void)cutBarTouchesDidEnd {
    self.playView.playerItem.forwardPlaybackEndTime = CMTimeMake(_videoConfig.endTime * 1000, 1000);
    if (self.playView.playerStatus == CropPlayerStatusPlayingBeforeSeek) {
        [self playVideo];
    }
}

- (void)playVideo {
    if (self.playView.playerStatus == CropPlayerStatusPlayingBeforeSeek) {
        CGFloat time = (self.cropView.siderTime+_videoConfig.startTime);
        if (self.cropView.siderTime+1>=_videoConfig.endTime-_videoConfig.startTime) {
            time=_videoConfig.startTime;
        }
        [self.playView.player seekToTime:CMTimeMake(time* 1000, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }
    
    [self.playView.player play];
    self.playView.playerStatus = CropPlayerStatusPlaying;
    
    [self removeTimeObserver];
    //    return;
    __weak __typeof(self) weakSelf = self;
    
    _timeObserver = [self.playView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10)
                                                                       queue:dispatch_get_main_queue()
                                                                  usingBlock:^(CMTime time) {
        __strong __typeof(self) strong = weakSelf;
        CGFloat crt = CMTimeGetSeconds(time);
        if (self.playView.playerStatus == CropPlayerStatusPlayingBeforeSeek||self.playView.playerStatus==CropPlayerStatusPause) {
            return ;
        }
        //        if (self->_videoConfig.endTime <= self->_videoConfig.startTime) {
        //            return;
        //        }
        [strong.cropView updateProgressViewWithProgress:(crt-self->_videoConfig.startTime)/(self->_videoConfig.endTime-self->_videoConfig.startTime)];
    }];
}

-(void)videoReadyToPlay{
    self.playView.playerStatus = CropPlayerStatusPlayingBeforeSeek;
    [self playVideo];
    [self.cropView loadThumbnailData];
}

- (SCJVideoPlayView *)playView {
    if (!_playView) {
        _playView = [[SCJVideoPlayView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight - 96 -kIPhoneInditorBottomMargin - kNavHeight) withModel:self.videoModel];
        _playView.delegate = self;
    }
    return _playView;
}

- (SCJVideoCropView *)cropView {
    if (!_cropView) {
        _cropView = [[SCJVideoCropView alloc] initWithFrame:CGRectMake(0, kScreenHeight - 120 -kIPhoneInditorBottomMargin - kNavHeight, kScreenWidth, 120 + kIPhoneInditorBottomMargin) videoConfig:_videoConfig];
        _cropView.avAsset = self.videoModel.avAsset;
        _cropView.delegate = self;
    }
    return _cropView;
}

@end
