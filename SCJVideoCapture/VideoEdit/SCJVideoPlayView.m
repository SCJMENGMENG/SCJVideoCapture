//
//  SCJVideoPlayView.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoPlayView.h"

static  NSString *videoPath = @"status";

@interface SCJVideoPlayView ()
@property (nonatomic, strong) SCJVideoModel *model;
@end

@implementation SCJVideoPlayView

- (instancetype)initWithFrame:(CGRect)frame withModel:(SCJVideoModel *)model {
    if (self=[super initWithFrame:frame]) {
        self.model = model;
         [self Config];
    }
    return self;
}

-(void)Config{
    self.playerItem = [[AVPlayerItem alloc] initWithAsset:self.model.avAsset];
    //监听播放器的状态，准备好播放、失败、未知错误
    [self.playerItem addObserver:self forKeyPath:videoPath options:NSKeyValueObservingOptionNew context:nil];
//    //    监听缓存的时间
//    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
//    //    监听获取当缓存不够，视频加载不出来的情况：
//    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//    //    用于监听缓存足够播放的状态
//    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    self.userInteractionEnabled=YES;
    
    //点击暂停
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseClick)]];
}
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer *)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:videoPath]) {
        AVPlayerItemStatus status = self.playerItem.status;
        if (status == AVPlayerItemStatusReadyToPlay) {
            if ([_delegate respondsToSelector:@selector(videoReadyToPlay)]) {
                [_delegate videoReadyToPlay];
            }
            [self.playerItem removeObserver:self forKeyPath:videoPath];
            //            _cutInfo.sourceDuration = [_playerItem.asset avAssetVideoTrackDuration];
            //            if (_cutInfo.endTime == 0) {
            //                _cutInfo.startTime = 0.0;
            //                _cutInfo.endTime = _cutInfo.sourceDuration;
            //            }
            //            _playerStatus = AliyunCropPlayerStatusPlayingBeforeSeek;
            //            [self playVideo];
            //            [_thumbnailView loadThumbnailData];
            //            [self removeObserver:self forKeyPath:PlayerItemStatus];
            //            _KVOHasRemoved = YES;
        }else if (status == AVPlayerItemStatusFailed){
            NSLog(@"系统播放器无法播放视频=== %@",keyPath);
        }
    }
}
#pragma mark  播放完成
- (void)moviePlayDidEnd:(NSNotification *)notification {
    [self.player pause];
    AVPlayerItem *p = [notification object];
    [p seekToTime:CMTimeMake(self.videoConfig.startTime * 1000, 1000) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.player play];
}

- (void)play {
    [self.player play];
    self.playerStatus=CropPlayerStatusPlaying;
}

- (void)playPauseClick {
    if (self.playerStatus==CropPlayerStatusPause) {
        self.playerStatus=CropPlayerStatusPlaying;
        [self.player play];
    }else{
        self.playerStatus=CropPlayerStatusPause;
        [self.player pause];
    }
}

@end
