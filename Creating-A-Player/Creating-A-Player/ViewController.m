//
//  ViewController.m
//  Creating-A-Player
//
//  Created by wangzhen on 17/6/13.
//  Copyright © 2017年 whrarest. All rights reserved.
//

#import "ViewController.h"
#import "WZPlayerView.h"
#import <AVFoundation/AVFoundation.h> // (We'll need this one later)
#import <MobileCoreServices/UTCoreTypes.h>

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet WZPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIButton *playPauseButton;
@property (nonatomic) AVPlayer *player;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (assign, nonatomic) BOOL isPlaying;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *timeLabelContainerView;

- (IBAction)uploadButtonTouched:(id)sender;
- (IBAction)playPauseButtonTouched:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;

@end

@implementation ViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 事件
- (void)uploadButtonTouched:(id)sender
{
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    self.imagePickerController.delegate = self;
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"视频" message:@"选择来源" preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"相机" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)playPauseButtonTouched:(id)sender
{
    if(self.isPlaying)
    {
        [self.player pause];
        [self.playPauseButton setTitle:@"播放" forState:UIControlStateNormal];
        [self.timer invalidate];
    }else{
        [self.player play];
        [self.playPauseButton setTitle:@"暂停" forState:UIControlStateNormal];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    }
    self.isPlaying = !self.isPlaying;
}


- (void)sliderValueChanged:(UISlider *)sender
{
    [self.player seekToTime:CMTimeMakeWithSeconds(sender.value, NSEC_PER_SEC)];
    [self updateTimeLabel];
}

#pragma mark - 定时器
- (void)updateSlider {
    CGFloat val = self.slider.value + 0.1f;
    [self.slider setValue:val];
    [self updateTimeLabel];
}

#pragma mark - UIImagePickerController

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *fileURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSLog(@"File URL String: %@", fileURL);
    
    self.playerItem = [AVPlayerItem playerItemWithURL:fileURL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [self.playerView setPlayer:self.player];
    self.uploadButton.hidden = YES;
    self.playPauseButton.hidden = NO;
    
    //slider
    self.slider.maximumValue = CMTimeGetSeconds(self.playerItem.asset.duration);
    self.slider.hidden = NO;
    
    //时间
    self.timeLabelContainerView.hidden = NO;
    Float64 durInMiliSec = 1000 * CMTimeGetSeconds(self.playerItem.asset.duration);
    self.timeLabel.text = [self formatInterval:durInMiliSec];
}

#pragma mark - 显示时间相关
- (void)updateTimeLabel {
    Float64 dur = CMTimeGetSeconds([self.player currentTime]);
    Float64 durInMiliSec = 1000*dur;
    self.timeLabel.text = [self formatInterval:durInMiliSec];
}

- (NSString *)formatInterval:(Float64)totalMilliseconds {
    unsigned long milliseconds = totalMilliseconds;
    unsigned long seconds = milliseconds / 1000;
    milliseconds %= 1000;
    unsigned long minutes = seconds / 60;
    seconds %= 60;
    return [NSString stringWithFormat:@"%02lu:%02lu.%02lu",minutes, seconds, milliseconds];
}

#pragma mark - 通知
//播放结束
- (void)itemDidFinishPlaying:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
    self.isPlaying = NO;
    [self.playPauseButton setTitle:@"播放" forState:UIControlStateNormal];
    [self.timer invalidate];
    [self.slider setValue:0];
}

@end
