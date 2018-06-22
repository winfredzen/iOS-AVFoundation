//
//  ViewController.m
//  PlayerComponent
//
//  Created by 王振 on 2018/6/22.
//  Copyright © 2018年 wz. All rights reserved.
//

#import "ViewController.h"
#import "WZBrightnessView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>


// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@interface ViewController ()

@property (nonatomic, strong) UISlider *volumeViewSlider;

/** 定义一个实例变量，保存枚举值 */
@property (nonatomic, assign) PanDirection           panDirection;

/** 是否在调节音量*/
@property (nonatomic, assign) BOOL                   isVolume;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self configureVolume];
    
    //拖动手势
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:panGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    WZBrightnessView *brightnessView = [WZBrightnessView sharedBrightnessView];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)panGesture:(UIPanGestureRecognizer *)panGesture {
    CGPoint locationPoint = [panGesture locationInView:self.view];
    CGPoint veloctyPoint = [panGesture velocityInView:self.view];
    NSLog(@"%@", NSStringFromCGPoint(veloctyPoint));
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateBegan: {
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                // 取消隐藏
                self.panDirection = PanDirectionHorizontalMoved;
            } else if (x < y) { // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > CGRectGetWidth(self.view.frame) / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
        
            break;
        }
        case UIGestureRecognizerStateChanged:
            if (self.panDirection == PanDirectionVerticalMoved) {
                if (self.isVolume) {
                    self.volumeViewSlider.value -= veloctyPoint.y / 10000;
                }else{
                    [UIScreen mainScreen].brightness -= veloctyPoint.y / 10000;
                }
            }
            break;
            
        default:
            break;
    }
}

/**
 *  获取系统音量
 */
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
}

@end
