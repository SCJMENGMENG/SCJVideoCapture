//
//  SCJVideoManager.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoManager.h"

static NSString *const folderName = @"SCJVideo";
static NSString *const plistName = @"SCJAsset";

@interface SCJVideoManager ()

@end

@implementation SCJVideoManager {
    UIImage *_firstImg;
}

- (instancetype)init {
    if ([super init]) {
        [self createFolder];
    }
    return self;
}

- (void)createFolder {
    if (![self isExistFolder]) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            //添加HUD文件夹
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:folderName];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                NSLog(@"创建相册文件夹成功!");
            } else {
                NSLog(@"创建相册文件夹失败:%@", error);
            }
        }];
    }
}

- (BOOL)isExistFolder {
    //首先获取用户手动创建相册的集合
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    __block BOOL isExisted = NO;
    //对获取到集合进行遍历
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        //folderName是我们写入照片的相册
        if ([assetCollection.localizedTitle isEqualToString:folderName])  {
            isExisted = YES;
        }
    }];
    
    return isExisted;
}


- (void)saveVideoPath:(NSURL *)videoPath completion:(returnBlock)completion {
    __weak __typeof(&*self)weakSelf = self;
    //首先获取相册的集合
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    //对获取到集合进行遍历
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        //folderName是我们写入照片的相册
        if ([assetCollection.localizedTitle isEqualToString:folderName])  {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                //请求创建一个Asset
                PHAssetChangeRequest *assetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoPath];
                //请求编辑相册
                PHAssetCollectionChangeRequest *collectonRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
                //为Asset创建一个占位符，放到相册编辑请求中
                PHObjectPlaceholder *placeHolder = [assetRequest placeholderForCreatedAsset];
                //相册中添加视频
                [collectonRequest addAssets:@[placeHolder]];
            } completionHandler:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"保存视频成功!");
                    [weakSelf readVideoWithCompletion:completion ? completion : nil];
                } else {
                    NSLog(@"保存视频失败:%@", error);
                }
            }];
        }
    }];
}

- (void)cutVideoWithAVAsset:(AVAsset *)avAsset startTime:(CGFloat)startTime endTime:(CGFloat)endTime completion:(returnBlock)completion {
    __weak __typeof(&*self)weakSelf = self;
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        
        NSURL *videoPath = [self filePathWithFileName:@"cutVideo.mp4"];
        
        [self cutVideoWithAVAsset:avAsset startTime:startTime endTime:endTime filePath:videoPath completion:^(NSURL *outputURL) {
            self->_firstImg = [weakSelf getVideoFirstViewImage:outputURL];
            [self saveVideoPath:outputURL completion:completion ? completion : nil];
        }];
        
    }
}

//导出剪切后的视频url
- (void)cutVideoWithAVAsset:(AVAsset *)asset startTime:(CGFloat)startTime endTime:(CGFloat)endTime filePath:(NSURL *)filePath completion:(saveDoneBlock)completion
{
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                           initWithAsset:asset presetName:AVAssetExportPresetPassthrough];
    exportSession.outputURL = filePath;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    
    CMTime start = CMTimeMakeWithSeconds(startTime, asset.duration.timescale);
    CMTime duration = CMTimeMakeWithSeconds(endTime - startTime,asset.duration.timescale);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
            NSLog(@"导出成功");
            if (completion) {
                completion(exportSession.outputURL);
            }
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"导出失败");
            });
        }
    }];
}

//保存文件路径
- (NSURL *)filePathWithFileName:(NSString *)fileName
{
    // 获取沙盒 temp 路径
    NSString *tempPath = NSTemporaryDirectory();
    tempPath = [tempPath stringByAppendingPathComponent:@"Video"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    // 判断文件夹是否存在 不存在创建
    BOOL exits = [manager fileExistsAtPath:tempPath isDirectory:nil];
    if (!exits) {
        
        // 创建文件夹
        [manager createDirectoryAtPath:tempPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 创建视频存放路径
    tempPath = [tempPath stringByAppendingPathComponent:fileName];
    
    // 判断文件是否存在
    if ([manager fileExistsAtPath:tempPath isDirectory:nil]) {
        // 存在 删除之前的视频
        [manager removeItemAtPath:tempPath error:nil];
    }
    
    return [NSURL fileURLWithPath:tempPath];
}

//获取视频Asset
- (void)readVideoWithCompletion:(returnBlock)completion {
    __weak __typeof(&*self)weakSelf = self;
    
    __block PHAsset *avsset = [[PHAsset alloc] init];
    
    PHFetchResult *collectonResuts = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    [collectonResuts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        PHAssetCollection *assetCollection = obj;
        if ([assetCollection.localizedTitle isEqualToString:folderName])  {
            PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:[PHFetchOptions new]];
            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PHAsset *asset = obj;
                
                avsset = asset;
            }];
        }
    }];
    
    [weakSelf returVideoPathWithAsset:avsset completion:completion ? completion : nil];
}

//获取视频文件路径
- (void)returVideoPathWithAsset:(PHAsset *)asset completion:(returnBlock)completion {
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = true; // iCloud的相册需要网络许可
    
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset * _Nullable avasset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            AVURLAsset *urlAsset = (AVURLAsset *)avasset;

            NSString *path = [[urlAsset.URL absoluteString] substringFromIndex:8];//// file:///var/mobile/Media/DCIM/100APPLE/IMG_0479.MP4
            if (completion) {
                completion(self->_firstImg,path);
            }
        });
    }];
}

// 获取视频第一帧
- (UIImage*)getVideoFirstViewImage:(NSURL *)path {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    assetGen.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

@end
