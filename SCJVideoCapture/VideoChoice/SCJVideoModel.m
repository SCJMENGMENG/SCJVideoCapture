//
//  SCJVideoModel.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoModel.h"

@implementation SCJVideoModel

+ (instancetype)modelWithAsset:(PHAsset *)asset timeLength:(NSString *)timeLength duration:(NSInteger)duration {
    SCJVideoModel *model = [[SCJVideoModel alloc] init];
    model.asset = asset;
    model.timeLength = timeLength;
    model.hideVideo = duration <=60 && duration >=1;
    model.duration = duration;
    
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (avAsset) {
            model.avAsset = avAsset;
        }
        if (!avAsset) {
            NSLog(@"-----avAsset为空,没有视频!!!!!");
        }
    }];
    
    return model;
}
@end

@implementation SCJVideoInfoConfig

@end
