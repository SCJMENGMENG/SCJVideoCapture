//
//  SCJVideoManager.h
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import <UIKit/UIKit.h>

typedef void(^saveDoneBlock)(NSURL *outputURL);
typedef void(^returnBlock)(UIImage *firstImg, NSString *filePath);

@interface SCJVideoManager : NSObject


/**
*  保存视频到系统相册
*
*  @param videoPath  保存的视频路径
   @param completion 回调视频名字
*/
- (void)saveVideoPath:(NSURL *)videoPath completion:(returnBlock)completion;

/**
*  获取视频
   @param completion 回调视频名字
*/
- (void)readVideoWithCompletion:(returnBlock)completion;

/**
 根据时间裁剪

 @param avAsset avAsset
 @param startTime 起始时间
 @param endTime 结束时间
 @param completion 回调视频名字
 */
- (void)cutVideoWithAVAsset:(AVAsset *)avAsset startTime:(CGFloat)startTime endTime:(CGFloat)endTime completion:(returnBlock)completion;


@end

