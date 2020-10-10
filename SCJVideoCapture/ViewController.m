//
//  ViewController.m
//  SCJVideoCapture
//
//  Created by scj on 2020/10/9.
//  Copyright © 2020 scj. All rights reserved.
//

#import "ViewController.h"
#import "SCJVideoSelectController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *pushBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
}

- (void)initUI {
    self.navigationController.navigationBar.hidden = YES;
    [self.view addSubview:self.pushBtn];
}

- (void)pushBtnClick {
    SCJVideoController *videoVC = [[SCJVideoController alloc] init];
    videoVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:videoVC animated:YES completion:nil];
}

- (UIButton *)pushBtn {
    if (!_pushBtn) {
        _pushBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_pushBtn setTitle:@"跳转" forState:UIControlStateNormal];
        [_pushBtn setBackgroundColor:[UIColor greenColor]];
        _pushBtn.frame = CGRectMake(100, 100, 100, 50);
        [_pushBtn addTarget:self action:@selector(pushBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _pushBtn;
}

@end
