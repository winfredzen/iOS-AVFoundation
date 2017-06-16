//
//  MIT License
//
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "THPlayerController.h"
#import "THThumbnail.h"
#import <AVFoundation/AVFoundation.h>
#import "THTransport.h"
#import "THPlayerView.h"
#import "AVAsset+THAdditions.h"
#import "UIAlertView+THAdditions.h"
#import "THNotifications.h"
#import "THThumbnail.h"

// AVPlayerItem's status property
#define STATUS_KEYPATH @"status"

// Refresh interval for timed observations of AVPlayer
#define REFRESH_INTERVAL 0.5f

// Define this constant for the key-value observation context.
static const NSString *PlayerItemStatusContext;


@interface THPlayerController () <THTransportDelegate>

@property (strong, nonatomic) THPlayerView *playerView;

@property (strong, nonatomic) AVAsset *asset;

@property (strong, nonatomic) AVPlayerItem *playerItem;

@property (strong, nonatomic) AVPlayer *player;

@property (weak, nonatomic) id<THTransport> transport;

@property (strong, nonatomic) id timeObserver;

@property (strong, nonatomic) id itemEndObserver;

@property (assign, nonatomic) float lastPlaybackRate;

//生成图片
@property (strong, nonatomic) AVAssetImageGenerator *imageGenerator;

@end

@implementation THPlayerController

- (void)dealloc
{
    //移除itemEndObserver
    if (self.itemEndObserver) {
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc removeObserver:self.itemEndObserver name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
        self.itemEndObserver = nil;
        
    }
}

#pragma mark - Setup

- (id)initWithURL:(NSURL *)assetURL {
    self = [super init];
    if (self) {
        
        _asset = [AVAsset assetWithURL:assetURL];
        [self prepareToPlay];
        
    }
    return self;
}

- (void)prepareToPlay {

    NSArray *keys = @[@"tracks", @"durations", @"commonMetadata", @"availableMediaCharacteristicsWithMediaSelectionOptions"];
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset automaticallyLoadedAssetKeys:keys];
    //KVO监听self.playerItem的status属性
    [self.playerItem addObserver:self forKeyPath:STATUS_KEYPATH options:0 context:&PlayerItemStatusContext];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    self.playerView = [[THPlayerView alloc] initWithPlayer:self.player];
    self.transport = self.playerView.transport;
    self.transport.delegate = self;
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if(context == &PlayerItemStatusContext)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
            //状态变为AVPlayerItemStatusReadyToPlay才可以开始播放
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
                //设置播放器的时间监视器
                [self addPlayerItemTimeObserver];
                [self addItemEndObserverForPlayerItem];
                
                CMTime duration = self.playerItem.duration;
                
                //设置当前时间和总长
                [self.transport setCurrentTime:CMTimeGetSeconds(kCMTimeZero) duration:CMTimeGetSeconds(duration)];
                //设置标题字符串
                [self.transport setTitle:self.asset.title];
                
                //播放视频
                [self.player play];
                
                //生成图片
                [self generateThumbnails];
                
                //字幕相关
                [self loadMediaOptions];
                
            }else{
                
                [UIAlertView showAlertWithTitle:@"错误" message:@"加载视频失败"];
                
            }
        });
    }
    
}

#pragma mark - Time Observers
//定期监听
- (void)addPlayerItemTimeObserver {

    //0.5s刷新
    CMTime interval = CMTimeMakeWithSeconds(REFRESH_INTERVAL, NSEC_PER_SEC);
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    __weak THPlayerController *weakSelf = self;
    
    void(^callback)(CMTime time) = ^(CMTime time){
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        NSTimeInterval duration = CMTimeGetSeconds(self.playerItem.duration);
        [weakSelf.transport setCurrentTime:currentTime duration:duration];
        
    };
    //添加observer，并保存以未来使用
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:callback];

    
}

//条目播放完毕监听
- (void)addItemEndObserverForPlayerItem {

    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    
    __weak THPlayerController *weakSelf = self;
    void (^callback)(NSNotification *note) = ^(NSNotification *notification){
        //重新定位播放头光标回到0位置
        [weakSelf.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            //播放完毕
            [weakSelf.transport playbackComplete];
        }];
    };
    
    self.itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                             object:self.playerItem
                                                                              queue:queue
                                                                         usingBlock:callback];
    
}

#pragma mark - THTransportDelegate Methods

- (void)play {

    [self.player play];
    
}

- (void)pause {

    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    
}

- (void)stop {

    [self.player setRate:0.0f];
    [self.transport playbackComplete];
    
}

- (void)jumpedToTime:(NSTimeInterval)time {

    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    
}

#pragma mark - 擦拭条相关

- (void)scrubbingDidStart {

    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    [self.player removeTimeObserver:self.timeObserver];
    
}

- (void)scrubbedToTime:(NSTimeInterval)time {

    //如果前一个搜索请求没有完成，则避免出现搜索操作堆积情况的出现
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
    
}

- (void)scrubbingDidEnd {

    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        [self.player play];
    }
    
}


#pragma mark - Thumbnail Generation

- (void)generateThumbnails {

    self.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.asset];
    self.imageGenerator.maximumSize = CGSizeMake(200.0f, 0.0f);
    
    CMTime duration = self.asset.duration;
    
    NSMutableArray *times = [NSMutableArray array];
    CMTimeValue increment = duration.value / 20;
    CMTimeValue currentValue = kCMTimeZero.value;
    while (currentValue <= duration.value) {
        CMTime time = CMTimeMake(currentValue, duration.timescale);
        [times addObject:[NSValue valueWithCMTime:time]];
         currentValue += increment;
    }
    
    __block NSUInteger imageCount = times.count;
    __block NSMutableArray *images = [NSMutableArray array];
    
    [self.imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable imageRef, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *image = [UIImage imageWithCGImage:imageRef];
            id thumbnail = [THThumbnail thumbnailWithImage:image time:actualTime];
            [images addObject:thumbnail];
        }else{
            NSLog(@"Failded to create thumbnail image.");
        }
        
        if (--imageCount == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *name = THThumbnailsGeneratedNotification;
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                [nc postNotificationName:name object:images];
            });
        }
        
    }];

}

#pragma mark - 字幕相关
- (void)loadMediaOptions {

    NSString *mc = AVMediaCharacteristicLegible;
    //Pass AVMediaCharacteristicLegible to obtain the group of available options for subtitles in various languages and for various purposes.
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group) {
        NSMutableArray *subtitles = [NSMutableArray array];
        for (AVMediaSelectionOption *option in group.options) {
            [subtitles addObject:option.displayName];
        }
        [self.transport setSubtitles:subtitles];
    }else {
        [self.transport setSubtitles:nil];
    }
    
}

- (void)subtitleSelected:(NSString *)subtitle {

    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    BOOL selected = NO;
    for (AVMediaSelectionOption *option in group.options) {
        if ([option.displayName isEqualToString:subtitle]) {
            [self.playerItem selectMediaOption:option inMediaSelectionGroup:group];
            selected = YES;
        }
    }
    if (!selected) {
        [self.playerItem selectMediaOption:nil inMediaSelectionGroup:group];
    }
    
}


#pragma mark - Housekeeping

- (UIView *)view {
    return self.playerView;
}

@end
