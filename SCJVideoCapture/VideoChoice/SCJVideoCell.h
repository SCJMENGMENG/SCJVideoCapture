//
//  SCJVideoCell.h
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

@class SCJVideoModel;
@interface SCJVideoCell : UICollectionViewCell
@property (nonatomic, strong) SCJVideoModel *model;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@property (nonatomic, assign) int32_t imageRequestID;
@end


@interface SCJVideoCropCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *videoImg;
@end
