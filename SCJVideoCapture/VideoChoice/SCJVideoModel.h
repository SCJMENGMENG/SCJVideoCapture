//
//  SCJVideoModel.h
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCJVideoModel : NSObject
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, copy) NSString *timeLength;
@property (nonatomic, assign) NSInteger duration;
@property (nonatomic, assign) BOOL hideVideo;
@property (nonatomic, strong) AVAsset *avAsset;

+ (instancetype)modelWithAsset:(PHAsset *)asset timeLength:(NSString *)timeLength duration:(NSInteger)duration;
@end

@interface SCJVideoInfoConfig : NSObject
/**
 视频时长
 */
@property (nonatomic, assign) CGFloat sourceDuration;
/**
 开始时间
 */
@property (nonatomic, assign) CGFloat startTime;
/**
 结束时间
 */
@property (nonatomic, assign) CGFloat endTime;

/**
 最小时长
 */
@property (nonatomic, assign) CGFloat minDuration;

/**
 最大时长
 */
@property (nonatomic, assign) CGFloat maxDuration;
@end

NS_ASSUME_NONNULL_END
