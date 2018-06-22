//
//  WZBrightnessView.m
//  PlayerComponent
//
//  Created by 王振 on 2018/6/22.
//  Copyright © 2018年 wz. All rights reserved.
//

#import "WZBrightnessView.h"

#define kWZBrightnessViewDefaultWidth 155.0f

@interface WZBrightnessView()

@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UIImageView *backImage;
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIView *longView;
@property (nonatomic, strong) NSMutableArray *tipArray;
@property (nonatomic, assign) BOOL orientationDidChange;

@end

@implementation WZBrightnessView

- (void)dealloc {
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedBrightnessView {
    static WZBrightnessView *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WZBrightnessView alloc] initWithFrame:CGRectZero];
        [[UIApplication sharedApplication].keyWindow addSubview:instance];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUI];
    }
    return self;
}

- (void)setUI {
    self.frame = CGRectMake(0, 0, kWZBrightnessViewDefaultWidth, kWZBrightnessViewDefaultWidth);
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius  = 10;
    self.layer.masksToBounds = YES;
    
    //使用UIToolbar实现毛玻璃效果，简单粗暴，支持iOS7+
    [self addSubview:self.toolBar];
    [self addSubview:self.backImage];
    [self addSubview:self.title];
    [self addSubview:self.longView];
    
    [self createTips];
    [self addNotification];
    [self addObserver];
    
    self.alpha = 0.0;
}

// 创建 Tips
- (void)createTips {
    
    self.tipArray = [NSMutableArray arrayWithCapacity:16];
    
    CGFloat tipW = (CGRectGetWidth(self.longView.frame) - 17) / 16;
    CGFloat tipH = 5;
    CGFloat tipY = 1;
    
    for (int i = 0; i < 16; i++) {
        CGFloat tipX          = i * (tipW + 1) + 1;
        UIImageView *image    = [[UIImageView alloc] init];
        image.backgroundColor = [UIColor whiteColor];
        image.frame           = CGRectMake(tipX, tipY, tipW, tipH);
        [self.longView addSubview:image];
        [self.tipArray addObject:image];
    }
    [self updateLongView:[UIScreen mainScreen].brightness];
}

#pragma makr - 通知 KVO

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateLayer:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)addObserver {
    [[UIScreen mainScreen] addObserver:self
                            forKeyPath:@"brightness"
                               options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    CGFloat brightness = [change[@"new"] floatValue];
    [self appearBrightnessView];
    [self updateLongView:brightness];
}

- (void)updateLayer:(NSNotification *)notify {
    self.orientationDidChange = YES;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Methond

- (void)appearBrightnessView {
    if (self.alpha == 0.0) {
        self.orientationDidChange = NO;
        self.alpha = 1.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self disAppearBrightnessView];
        });
    }
}

- (void)disAppearBrightnessView {
    
    if (self.alpha == 1.0) {
        [UIView animateWithDuration:0.8 animations:^{
            self.alpha = 0.0;
        }];
    }
}

#pragma mark - Update View

- (void)updateLongView:(CGFloat)brightness {
    CGFloat stage = 1 / 15.0;
    NSInteger level = brightness / stage;
    
    for (int i = 0; i < self.tipArray.count; i++) {
        UIImageView *img = self.tipArray[i];
        
        if (i <= level) {
            img.hidden = NO;
        } else {
            img.hidden = YES;
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.center = CGPointMake([[UIScreen mainScreen] bounds].size.width * 0.5, [[UIScreen mainScreen] bounds].size.height * 0.5);
}


#pragma mark - Access Method
- (UIToolbar *)toolBar {
    if (!_toolBar) {
        _toolBar = [[UIToolbar alloc] initWithFrame:self.bounds];
        _toolBar.alpha = 0.97;
    }
    return _toolBar;
}

- (UIImageView *)backImage
{
    if (!_backImage) {
        _backImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 79, 76)];
        _backImage.center = CGPointMake(CGRectGetWidth(self.frame) * 0.5, CGRectGetHeight(self.frame)  * 0.5);
//        NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"WZPlayer" withExtension:@"bundle"]];
//        NSString *imagePath = [bundle pathForResource:@"ZFPlayer_brightness" ofType:@"png"];
//        UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
//        _backImage.image = image;
        
        _backImage.image = [UIImage imageNamed:@"WZPlayer.bundle/ZFPlayer_brightness.png"];
        
    }
    return _backImage;
}

- (UILabel *)title
{
    if (!_title) {
        _title = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, CGRectGetWidth(self.frame), 30)];
        _title.font = [UIFont boldSystemFontOfSize:16];
        _title.textColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
        _title.textAlignment = NSTextAlignmentCenter;
        _title.text = @"亮度";
    }
    return _title;
}

- (UIView *)longView
{
    if (!_longView) {
        _longView = [[UIView alloc]initWithFrame:CGRectMake(13, 132, self.bounds.size.width - 26, 7)];
        _longView.backgroundColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.00f];
    }
    return _longView;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
