//
//  SCJVideoCropView.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoCropView.h"
#import "SCJVideoModel.h"
#import "SCJVideoCell.h"
#import "UIView+SCJ.h"

#import <YYKit/YYKit.h>
#import <Masonry.h>

#define kEndTime  15    //最大截取秒数
#define kPicNumber 15.0 //框里放多少张图

@interface SCJVideoCropView ()<UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource>
{
    NSInteger _itemCount; //缩略图个数
    CGFloat _perSpWith;// 每秒占宽度
    CGFloat _itemWidth; //cellWidth
    CGFloat _cropWidth; // 15s 宽度
    CGFloat _maxScreenDuraion;//整个屏幕最大时长
    CGFloat _selectTime;//已选择的时间
    SCJVideoInfoConfig *_videoConfig;
    CGFloat _imageViewWith;//左右图片宽度
    UIColor *_itemBackgroundColor;//item整体颜色
    CGFloat _margion;//左右间距
}
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIView *durationView;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) NSMutableArray *imagesArray;
@property (nonatomic, strong) UIImageView *imageViewLeft;
@property (nonatomic, strong) UIImageView *imageViewRight;
@property (nonatomic, strong) UIView *imageViewSelected;
@property (nonatomic, strong) UIButton *progressView;
@property (nonatomic, strong) UIImageView *topLineView;
@property (nonatomic, strong) UIImageView *underLineView;
@property (nonatomic, strong) UILabel *explainLabel;
@end

@implementation SCJVideoCropView

- (instancetype)initWithFrame:(CGRect)frame videoConfig:(SCJVideoInfoConfig *)config {
    _videoConfig = config;
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.userInteractionEnabled = YES;
    
    _itemBackgroundColor = [UIColor colorWithRed:82/255.0 green:122/255.0 blue:255/255.0 alpha:1];
    self.clipsToBounds = NO;
    
    _imageViewWith = 16;
    _margion = 20;
    _cropWidth = self.width - 2*_margion - 2*_imageViewWith;
    
    _itemWidth = _cropWidth / kPicNumber;
    _imagesArray = [NSMutableArray array];
    
    if (_videoConfig.sourceDuration <= kEndTime) {
        _videoConfig.endTime = _videoConfig.sourceDuration;
        _maxScreenDuraion = _videoConfig.endTime;
        _itemCount = kPicNumber;
    }
    else {
        _videoConfig.endTime = kEndTime;
        _maxScreenDuraion = _videoConfig.endTime;
        _itemCount = (int)roundf(_videoConfig.sourceDuration / (_maxScreenDuraion / kPicNumber));//四舍五入
    }
    
    _perSpWith = (_itemWidth * _itemCount) / _videoConfig.sourceDuration;
    
    [self setupSubviews];
}


- (void)setupSubviews {
    UICollectionViewFlowLayout *followLayout = [[UICollectionViewFlowLayout alloc] init];
    followLayout.itemSize = CGSizeMake(_itemWidth , 50);
    followLayout.minimumLineSpacing = 0;
    followLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 29, self.width, 50) collectionViewLayout:followLayout];
    self.collectionView.contentInset = UIEdgeInsetsMake(0, _margion +_imageViewWith, 0, _margion +_imageViewWith);
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.alwaysBounceHorizontal = YES;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.delegate= self;
    self.collectionView.dataSource = self;
    [self.collectionView registerClass:[SCJVideoCropCell class] forCellWithReuseIdentifier:[SCJVideoCropCell className]];
    self.collectionView.clipsToBounds=NO;
    [self addSubview:self.collectionView];
    
    self.durationView = [[UIView alloc] init];
    self.durationView.bounds = CGRectMake(0, 0, 74, 20);
    self.durationView.center = CGPointMake(self.centerX, 10);
    self.durationView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    self.durationView.layer.maskedCorners = 10;
    self.durationView.layer.masksToBounds = YES;
    [self addSubview:self.durationView];
    
    self.durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 74, 20)];
    self.durationLabel.font = [UIFont systemFontOfSize:13];
    self.durationLabel.textColor = [UIColor whiteColor];
    self.durationLabel.textAlignment = NSTextAlignmentCenter;
    [self.durationView addSubview:self.durationLabel];
    
    self.imageViewLeft = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"diy_videoedit_left"]];
    self.imageViewLeft.contentMode = UIViewContentModeScaleAspectFit;
    self.imageViewLeft.frame = CGRectMake(_margion, self.collectionView.y -5, _imageViewWith, 60);
    self.imageViewLeft.userInteractionEnabled = YES;
    
    self.imageViewRight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"diy_videoedit_right"]];
    self.imageViewRight.frame = CGRectMake(self.width - _imageViewWith - _margion, self.collectionView.y -5, _imageViewWith, 60);
    self.imageViewRight.contentMode = UIViewContentModeScaleAspectFit;
    self.imageViewRight.userInteractionEnabled = YES;
    
    self.topLineView = [[UIImageView alloc] initWithFrame:CGRectMake(_margion +6, self.collectionView.y -5, self.width - 2*_margion -12, 5)];
    self.topLineView.backgroundColor = _itemBackgroundColor;
    
    self.underLineView = [[UIImageView alloc] initWithFrame:CGRectMake(self.topLineView.x, CGRectGetMaxY(self.collectionView.frame), self.topLineView.width, 5)];
    self.underLineView.backgroundColor = _itemBackgroundColor;
    
    [self addSubview:self.topLineView];
    [self addSubview:self.underLineView];
    [self addSubview:self.imageViewLeft];
    [self addSubview:self.imageViewRight];
    
    self.progressView = [[UIButton alloc] init];
    self.progressView.backgroundColor = [UIColor whiteColor];
    self.progressView.layer.maskedCorners = 2;
    self.progressView.layer.masksToBounds = YES;
    self.progressView.bounds = CGRectMake(0, 0, 4, 70);
    self.progressView.center = CGPointMake(0, self.collectionView.centerY);
    self.progressView.x = CGRectGetMaxX(self.imageViewLeft.frame);
    self.progressView.enabled = NO;
    self.progressView.userInteractionEnabled = YES;
    [self addSubview:self.progressView];
    
    self.explainLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, kScreenWidth, 30)];
    self.explainLabel.textAlignment = NSTextAlignmentCenter;
    self.explainLabel.text = @"注：需是单人全身视频且可显示肢体轮廓";
    self.explainLabel.font = [UIFont systemFontOfSize:13];
    self.explainLabel.textColor = [UIColor colorWithRed:266/255.0 green:165/255.0 blue:0 alpha:1];
    [self addSubview:self.explainLabel];
    
    UIImageView *viewLeft = [[UIImageView alloc] init];
    viewLeft.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    UIImageView *viewRight = [[UIImageView alloc] init];
    viewRight.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    [self addSubview:viewLeft];
    [self addSubview:viewRight];
    [viewLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.equalTo(self.imageViewLeft.mas_left);
        make.top.bottom.equalTo(self.imageViewLeft);
    }];
    [viewRight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(0);
        make.left.equalTo(self.imageViewRight.mas_right);
        make.top.bottom.equalTo(self.imageViewRight);
    }];
}

#pragma mark  加载视频截图
- (void)loadThumbnailData {
    self.durationLabel.text = [NSString stringWithFormat:@"已选取%@s",[NSString stringWithFormat:@"%.0f",_videoConfig.endTime - _videoConfig.startTime]];
    _selectTime = _videoConfig.endTime - _videoConfig.startTime;
    CMTime startTime = kCMTimeZero;
    NSMutableArray *array = [NSMutableArray array];
    CMTime addTime = CMTimeMake(1000,1000);
    CGFloat d = _videoConfig.sourceDuration / (_itemCount-1);
    float intd = d * 100.0;
    float fd = intd / 100.0;
    addTime = CMTimeMakeWithSeconds(fd, 1000);
    
    CMTime endTime = CMTimeMakeWithSeconds(_videoConfig.sourceDuration, 1000);
    
    while (CMTIME_COMPARE_INLINE(startTime, <=, endTime)) {
        [array addObject:[NSValue valueWithCMTime:startTime]];
        startTime = CMTimeAdd(startTime, addTime);
    }
    
    // 第一帧取第0.1s   规避有些视频并不是从第0s开始的
    array[0] = [NSValue valueWithCMTime:CMTimeMakeWithSeconds(0.1, 1000)];
    __weak __typeof(self) weakSelf = self;
    __block int index = 0;
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:array completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *img = [[UIImage alloc] initWithCGImage:image];
            dispatch_sync(dispatch_get_main_queue(), ^{
                [weakSelf.imagesArray addObject:img];
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [weakSelf.collectionView insertItemsAtIndexPaths:@[indexPath]];
                index++;
            });
        }
    }];
}
#pragma mark 调整进度条播放位置
- (void)updateProgressViewWithProgress:(CGFloat)progress {
    if (_imageViewSelected != nil) {
        return;
    }
    CGFloat width = CGRectGetMinX(self.imageViewRight.frame) - CGRectGetMaxX(self.imageViewLeft.frame);
    CGFloat newX = CGRectGetMaxX(self.imageViewLeft.frame)+ progress *width;
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveLinear |UIViewAnimationOptionAllowUserInteraction animations:^{
        weakSelf.progressView.x = newX;
    } completion:nil];
    [self layoutIfNeeded];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _imagesArray.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SCJVideoCropCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[SCJVideoCropCell className] forIndexPath:indexPath];
    cell.videoImg.image = _imagesArray[indexPath.row];
    return cell;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint point = [touch locationInView:self];
    CGRect adjustLeftRespondRect = self.imageViewLeft.frame;
    CGRect adjustRightRespondRect = self.imageViewRight.frame;
    CGRect adjustProgressRespondRect = CGRectMake(self.progressView.frame.origin.x-30, self.progressView.frame.origin.y, self.progressView.frame.size.width+60, self.progressView.frame.size.height) ;
    if (CGRectContainsPoint(adjustLeftRespondRect, point)) {
        _imageViewSelected = self.imageViewLeft;
    } else if (CGRectContainsPoint(adjustRightRespondRect, point)) {
        _imageViewSelected = self.imageViewRight;
    } else if (CGRectContainsPoint(adjustProgressRespondRect, point)) {
        _imageViewSelected = self.progressView;
    }
    else {
        _imageViewSelected = nil;
    }
}

#pragma mark  手指滑动截取视频
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!_imageViewSelected) return;
    
    UITouch *touch = (UITouch *)[touches anyObject];
    CGPoint lp = [touch locationInView:self.collectionView];
    CGPoint pp = [touch previousLocationInView:self.collectionView];
    CGFloat offset = lp.x - pp.x;
    if (_imageViewSelected == self.imageViewLeft) {
        CGRect frame = self.imageViewLeft.frame;
        frame.origin.x += offset;
        if (frame.origin.x<=_margion) {
            offset+=(_margion-frame.origin.x);
            frame.origin.x=_margion;
        }
        if (frame.origin.x>= CGRectGetMinX(self.imageViewRight.frame) - _perSpWith * _videoConfig.minDuration - _imageViewWith) {
            offset -= frame.origin.x - (CGRectGetMinX(self.imageViewRight.frame) - _perSpWith * _videoConfig.minDuration - _imageViewWith);
            
            frame.origin.x= CGRectGetMinX(self.imageViewRight.frame) - _perSpWith * _videoConfig.minDuration - _imageViewWith;
        }
        CGFloat time = offset/_perSpWith;
        CGFloat left = _videoConfig.startTime + time;
        _videoConfig.startTime = left;
        _imageViewLeft.frame = frame;
        _progressView.x = CGRectGetMaxX(self.imageViewLeft.frame);
        self.durationLabel.text = [NSString stringWithFormat:@"已选取%@s",[NSString stringWithFormat:@"%.0f",_videoConfig.endTime - _videoConfig.startTime]];
        _selectTime = _videoConfig.endTime - _videoConfig.startTime;
        if ([_delegate respondsToSelector:@selector(cutBarDidMovedToTime:)]) {
            [_delegate cutBarDidMovedToTime:left];
        }
    } else if (_imageViewSelected == _imageViewRight) {
        
        CGRect frame = _imageViewRight.frame;
        frame.origin.x += offset;
        
        if (frame.origin.x>=self.width-2*_margion +4) {
            offset-=frame.origin.x-(self.width-2*_margion +4);
            frame.origin.x=self.width-2*_margion +4;
        }
        
        if (frame.origin.x<=CGRectGetMaxX(self.imageViewLeft.frame)+_perSpWith*_videoConfig.minDuration) {
            offset+=(CGRectGetMaxX(self.imageViewLeft.frame)+_perSpWith*_videoConfig.minDuration)-frame.origin.x;
            frame.origin.x=CGRectGetMaxX(self.imageViewLeft.frame)+_perSpWith*_videoConfig.minDuration;
        }
        CGFloat time = offset/_perSpWith;
        CGFloat right = _videoConfig.endTime + time;
        _videoConfig.endTime = right;
        _imageViewRight.frame = frame;
        _progressView.x = CGRectGetMinX(self.imageViewRight.frame);
        self.durationLabel.text=[NSString stringWithFormat:@"已选取%@s",[NSString stringWithFormat:@"%.0f",_videoConfig.endTime - _videoConfig.startTime]];
        _selectTime =_videoConfig.endTime - _videoConfig.startTime;
        if ([_delegate respondsToSelector:@selector(cutBarDidMovedToTime:)]) {
            [_delegate cutBarDidMovedToTime:right];
        }
    }else if(_imageViewSelected == _progressView){
        CGRect frame = _progressView.frame;
        frame.origin.x += offset;
        if (frame.origin.x<=CGRectGetMaxX(self.imageViewLeft.frame)) {
            frame.origin.x=CGRectGetMaxX(self.imageViewLeft.frame);
        }
        if (frame.origin.x>=CGRectGetMinX(self.imageViewRight.frame)) {
            frame.origin.x=CGRectGetMinX(self.imageViewRight.frame);
        }
        _progressView.frame = frame;
        if ([_delegate respondsToSelector:@selector(cutBarDidMovedToTime:)]) {
            CGFloat progresstime=   (CGRectGetMinX(self.progressView.frame)-CGRectGetMaxX(self.imageViewLeft.frame))/_perSpWith;
            [_delegate cutBarDidMovedToTime:_videoConfig.startTime+progresstime];
        }
    }
    CGRect upFrame = _topLineView.frame;
    CGRect downFrame = _underLineView.frame;
    
    upFrame.origin.x = CGRectGetMaxX(_imageViewLeft.frame);
    downFrame.origin.x = upFrame.origin.x;
    
    upFrame.size.width = CGRectGetMinX(_imageViewRight.frame) - CGRectGetMaxX(_imageViewLeft.frame);
    downFrame.size.width = upFrame.size.width;
    
    _topLineView.frame = upFrame;
    _underLineView.frame = downFrame;
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _imageViewSelected = nil;
    if ([_delegate respondsToSelector:@selector(cutBarTouchesDidEnd)]) {
        [_delegate cutBarTouchesDidEnd];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGFloat time =(scrollView.contentOffset.x+30)/_perSpWith;
    if (time+(CGRectGetMaxX(self.imageViewLeft.frame)-30)/_perSpWith<0) {
        return;
    }
    _videoConfig.startTime = time+(CGRectGetMaxX(self.imageViewLeft.frame)-30)/_perSpWith;
    _videoConfig.endTime=_videoConfig.startTime+_selectTime;
    if ([_delegate respondsToSelector:@selector(cutBarDidMovedToTime:)]) {
        [_delegate cutBarDidMovedToTime:_videoConfig.startTime+self.siderTime];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if ([_delegate respondsToSelector:@selector(cutBarTouchesDidEnd)]) {
        [_delegate cutBarTouchesDidEnd];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (!decelerate) {
        if ([_delegate respondsToSelector:@selector(cutBarTouchesDidEnd)]) {
            [_delegate cutBarTouchesDidEnd];
        }
    }
}

-(CGFloat)siderTime{
    return  (CGRectGetMinX(self.progressView.frame)- CGRectGetMaxX(self.imageViewLeft.frame))/_perSpWith;
}

- (AVAssetImageGenerator *)imageGenerator {
    if (!_imageGenerator) {
        _imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:_avAsset];
        _imageGenerator.appliesPreferredTrackTransform = YES;
        _imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
        _imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        _imageGenerator.maximumSize = CGSizeMake(320, 320);
    }
    return _imageGenerator;
}

@end
