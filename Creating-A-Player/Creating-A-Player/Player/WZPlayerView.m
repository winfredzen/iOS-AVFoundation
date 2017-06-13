//
//  WZPlayerView.m
//  Creating-A-Player
//
//  Created by wangzhen on 17/6/13.
//  Copyright © 2017年 whrarest. All rights reserved.
//

#import "WZPlayerView.h"

@import AVFoundation;

@implementation WZPlayerView

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}


- (void)setPlayer:(AVPlayer *)player
{
    ((AVPlayerLayer *)[self layer]).videoGravity = AVLayerVideoGravityResizeAspectFill;
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
