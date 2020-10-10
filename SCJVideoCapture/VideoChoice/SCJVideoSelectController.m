//
//  SCJVideoSelectController.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "SCJVideoSelectController.h"
#import "SCJVideoCell.h"
#import "SCJVideoModel.h"
#import "UIImage+SCJ.h"
#import "SCJVideoEditController.h"

#import <TZImagePickerController.h>
#import <NSBundle+TZImagePicker.h>
#import <UIView+Layout.h>
#import <FDFullscreenPopGesture/UINavigationController+FDFullscreenPopGesture.h>

@implementation SCJVideoController {
    NSTimer *_timer;
    UILabel *_tipLabel;
    UIButton *_settingBtn;
}

- (instancetype)init {
    if (self = [super init]) {
        
        SCJVideoAlbumController *albumVC = [[SCJVideoAlbumController alloc] init];
        self = [super initWithRootViewController:albumVC];
        
        if (![[TZImageManager manager] authorizationStatusAuthorized]) {
            [self initUI];
            
            if ([PHPhotoLibrary authorizationStatus] == 0) {
                _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:NO];
            }
        }
        else {
            SCJVideoSelectController *selectVC = [[SCJVideoSelectController alloc] init];
            [self pushViewController:selectVC animated:NO];
        }
    }
    return self;
}

- (void)initUI {
    _tipLabel = [[UILabel alloc] init];
    _tipLabel.frame = CGRectMake(8, 120, self.view.tz_width - 16, 60);
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    _tipLabel.numberOfLines = 0;
    _tipLabel.font = [UIFont systemFontOfSize:16];
    _tipLabel.textColor = [UIColor blackColor];
    _tipLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    NSDictionary *infoDict = [TZCommonTools tz_getInfoDictionary];
    NSString *appName = [infoDict valueForKey:@"CFBundleDisplayName"];
    if (!appName) appName = [infoDict valueForKey:@"CFBundleName"];
    if (!appName) appName = [infoDict valueForKey:@"CFBundleExecutable"];
    NSString *tipText = [NSString stringWithFormat:[NSBundle tz_localizedStringForKey:@"Allow %@ to access your album in \"Settings -> Privacy -> Photos\""],appName];
    _tipLabel.text = tipText;
    [self.view addSubview:_tipLabel];
    
    _settingBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [_settingBtn setTitle:[NSBundle tz_localizedStringForKey:@"Setting"] forState:UIControlStateNormal];
    _settingBtn.frame = CGRectMake(0, 180, self.view.tz_width, 44);
    _settingBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [_settingBtn addTarget:self action:@selector(settingBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _settingBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self.view addSubview:_settingBtn];
}

- (void)observeAuthrizationStatusChange {
    [_timer invalidate];
    _timer = nil;
    if ([PHPhotoLibrary authorizationStatus] == 0) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(observeAuthrizationStatusChange) userInfo:nil repeats:NO];
    }
    
    if ([[TZImageManager manager] authorizationStatusAuthorized]) {
        [_tipLabel removeFromSuperview];
        [_settingBtn removeFromSuperview];
        
        SCJVideoSelectController *selectVC = [[SCJVideoSelectController alloc] init];
        [self pushViewController:selectVC animated:NO];
        
        //添加相册列表
    }
}

- (void)settingBtnClick {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (void)cancelButtonClick {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation SCJVideoAlbumController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor blackColor]] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    SCJVideoController *videoVc = (SCJVideoController *)self.navigationController;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:videoVc action:@selector(cancelButtonClick)];
    cancelItem.tintColor = [UIColor whiteColor];
    NSMutableDictionary *textAttrs = [NSMutableDictionary dictionary];
    textAttrs[NSForegroundColorAttributeName] = [UIColor whiteColor];
    textAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:15];
    [cancelItem setTitleTextAttributes:textAttrs forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = cancelItem;
}

@end

@interface SCJVideoSelectController ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) UILabel *noDataLabel;

@property (nonatomic, strong) NSMutableArray *assetArr;
@property (nonatomic, strong) NSMutableArray *dataSource;
@end

static CGFloat itemMargin = 5;
static NSInteger columnNumber = 4;

@implementation SCJVideoSelectController {
    NSInteger _albumCount;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.fd_fullscreenPopGestureRecognizer.enabled = NO;
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    self.navigationController.fd_fullscreenPopGestureRecognizer.enabled = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    [self getCameraRollAlbum];
    [self videoSort];
    [self configCollectionView];
}

- (void)initUI {
    self.title = @"视频相册";
    SCJVideoController *naviVC = (SCJVideoController *)self.navigationController;
    UIImage* itemImage= [UIImage imageNamed:@"diy_video_close"];
    itemImage = [itemImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithImage:itemImage style:UIBarButtonItemStylePlain target:naviVC action:@selector(cancelButtonClick)];
    self.navigationItem.leftBarButtonItem = cancelItem;
}

- (void)configCollectionView {
    self.layout = [[UICollectionViewFlowLayout alloc] init];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.alwaysBounceHorizontal = NO;
    self.collectionView.contentInset = UIEdgeInsetsMake(itemMargin, itemMargin, itemMargin, itemMargin);
    self.collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_albumCount + columnNumber - 1) / columnNumber) * self.view.tz_width);
    if (_albumCount == 0) {
        self.noDataLabel = [UILabel new];
        self.noDataLabel.textAlignment = NSTextAlignmentCenter;
        self.noDataLabel.text = @"无可用的视频";
        [self.collectionView addSubview:self.noDataLabel];
    }
    [self.view addSubview:self.collectionView];
    [self.collectionView registerClass:[SCJVideoCell class] forCellWithReuseIdentifier:@"SCJVideoCell"];
}

#pragma mark - Layout
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.collectionView.frame = CGRectMake(0, 0, self.view.tz_width, self.view.tz_height);
    _noDataLabel.frame = self.collectionView.bounds;
    CGFloat itemWH = (self.view.tz_width - (columnNumber + 1) * itemMargin) / columnNumber;
    self.layout.itemSize = CGSizeMake(itemWH, itemWH);
    self.layout.minimumInteritemSpacing = itemMargin;
    self.layout.minimumLineSpacing = itemMargin;
    [self.collectionView setCollectionViewLayout:self.layout];
}

#pragma mark - UICollectionViewDataSource && Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _albumCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SCJVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"SCJVideoCell" forIndexPath:indexPath];
    SCJVideoModel *model = self.dataSource[indexPath.item];
    cell.model = model;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SCJVideoModel *model = self.dataSource[indexPath.item];
    if (!model.hideVideo) {
        return;
    }
    
    SCJVideoEditController *editVC = [[SCJVideoEditController alloc] init];
    editVC.videoModel = model;
    [self.navigationController pushViewController:editVC animated:YES];
}

/// Get Album 获得相册/相册数组
- (void)getCameraRollAlbum {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
    PHAssetMediaTypeVideo];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        // 有可能是PHCollectionList类的的对象，过滤掉
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        // 过滤空相册
        if (collection.estimatedAssetCount <= 0) continue;
        if ([self isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            _albumCount = fetchResult.count;
            NSMutableArray *assetArr = [NSMutableArray array];
            [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
                [assetArr addObject:asset];
            }];
            self.assetArr = [NSMutableArray arrayWithArray:assetArr];
            break;
        }
    }
}

- (SCJVideoModel *)assetModelWithAsset:(PHAsset *)asset allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage {
    BOOL canSelect = YES;
    if (!canSelect) return nil;
    
    SCJVideoModel *model;
    
    PHAsset *phAsset = (PHAsset *)asset;
    NSString *duration = [NSString stringWithFormat:phAsset.duration < 1 ? @"%f" : @"%0.0f",phAsset.duration];//小于一秒的不可点击
    NSString *timeLength = [self getNewTimeFromDurationSecond:duration.integerValue];
    model = [SCJVideoModel modelWithAsset:asset timeLength:timeLength duration:duration.integerValue];
    return model;
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"00:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"00:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}
                                
- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 ~ 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

//视频排序
- (void)videoSort {
    NSArray *result = [self.assetArr sortedArrayUsingComparator:^NSComparisonResult(PHAsset *  _Nonnull obj1, PHAsset *  _Nonnull obj2) {
        NSInteger duration1 = [[NSString stringWithFormat:@"%0.0f",obj1.duration] integerValue];
        NSInteger duration2 = [[NSString stringWithFormat:@"%0.0f",obj2.duration] integerValue];
        if (duration1 < duration2) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedDescending;
        }
    }];
    
    for (int i = 0; i<result.count; i++) {
        PHAsset *asset = result[i];
        SCJVideoModel *model = [self assetModelWithAsset:asset allowPickingVideo:YES allowPickingImage:NO];
        [self.dataSource addObject:model];
    }
}

- (NSMutableArray *)assetArr {
    if (!_assetArr) {
        _assetArr = [[NSMutableArray alloc] init];
    }
    return _assetArr;;
}

- (NSMutableArray *)dataSource {
    if (!_dataSource) {
        _dataSource = [[NSMutableArray alloc] init];
    }
    return _dataSource;;
}

@end
