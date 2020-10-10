//
//  SCJVideoCell.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoCell.h"
#import "SCJVideoModel.h"

#import <UIView+Layout.h>
#import <TZImageManager.h>
#import <Masonry.h>

@interface SCJVideoCell ()
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIImageView *iconImg;
@property (nonatomic, strong) UILabel *timeLength;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIImageView *videoImg;
@property (nonatomic, assign) int32_t bigImageRequestID;
@end

@implementation SCJVideoCell

- (void)setModel:(SCJVideoModel *)model {
    _model = model;
    
    self.representedAssetIdentifier = model.asset.localIdentifier;
    int32_t imageRequestID = [[TZImageManager manager] getPhotoWithAsset:model.asset photoWidth:self.tz_width completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if ([self.representedAssetIdentifier isEqualToString:model.asset.localIdentifier]) {
            self.videoImg.image = photo;
        }
        else {
            [[PHImageManager defaultManager] cancelImageRequest:self.imageRequestID];
        }
        if (!isDegraded) {
            self.imageRequestID = 0;
        }
    } progressHandler:nil networkAccessAllowed:NO];
    self.imageRequestID = imageRequestID;
    
    self.timeLength.text = model.timeLength;
    
    self.maskView.hidden = model.hideVideo;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ([super initWithFrame:frame]) {
        [self setupSubViews];
    }
    return self;
}

- (void)setupSubViews {
    [self.contentView addSubview:self.videoImg];
    [self.contentView addSubview:self.maskView];
    [self.contentView addSubview:self.bottomView];
    [self.bottomView addSubview:self.iconImg];
    [self.bottomView addSubview:self.timeLength];
    
    [self.videoImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(4);
        make.bottom.mas_equalTo(-5);
        make.size.mas_equalTo(CGSizeMake(44, 16));
    }];
    [self.iconImg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(4);
        make.centerY.equalTo(self.bottomView);
        make.size.mas_equalTo(CGSizeMake(6, 8));
    }];
    [self.timeLength mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.iconImg.mas_right).offset(2);
        make.centerY.equalTo(self.bottomView);
    }];
}

- (UIImageView *)videoImg {
    if (!_videoImg) {
        _videoImg = [[UIImageView alloc] init];
        _videoImg.contentMode = UIViewContentModeScaleAspectFill;
        _videoImg.clipsToBounds = YES;
    }
    return _videoImg;
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        _maskView.hidden = YES;
    }
    return _maskView;
}

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _bottomView.layer.maskedCorners = 8;
        _bottomView.layer.masksToBounds = YES;
    }
    return _bottomView;
}

- (UILabel *)timeLength {
    if (!_timeLength) {
        _timeLength = [[UILabel alloc] init];
        _timeLength.font = [UIFont systemFontOfSize:10];
        _timeLength.textColor = [UIColor whiteColor];
    }
    return _timeLength;
}

- (UIImageView *)iconImg {
    if (!_iconImg) {
        _iconImg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"diy_video"]];
    }
    return _iconImg;
}
@end

@implementation SCJVideoCropCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initUI];
    }
    return self;
}

- (void)initUI {
    self.videoImg = [[UIImageView alloc] init];
    self.videoImg.frame = self.contentView.bounds;
    self.videoImg.contentMode = UIViewContentModeScaleAspectFill;
    self.videoImg.clipsToBounds = YES;
    [self addSubview:self.videoImg];
}
@end

