//
//  SCJVideoPlayView.h
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SCJVideoModel.h"

@class SCJVideoInfoConfig;
typedef NS_ENUM(NSInteger, CropPlayerStatus) {
    CropPlayerStatusPause,             // 结束或暂停
    CropPlayerStatusPlaying,           // 播放中
    CropPlayerStatusPlayingBeforeSeek  // 拖动之前是播放状态
};

@protocol SCJVideoPlayViewDelegate <NSObject>

@required
-(void)videoReadyToPlay;

@end

@interface SCJVideoPlayView : UIView

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic, assign) CropPlayerStatus playerStatus;
@property (nonatomic, strong) SCJVideoInfoConfig *videoConfig;
@property (nonatomic,weak) id <SCJVideoPlayViewDelegate>delegate;

- (id)initWithFrame:(CGRect)frame localUrl:(NSURL *)localUrl;
-(id)initWithFrame:(CGRect)frame withModel:(SCJVideoModel *)model;

-(void)play;
@end
