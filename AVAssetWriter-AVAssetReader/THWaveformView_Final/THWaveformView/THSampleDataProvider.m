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

#import "THSampleDataProvider.h"

@implementation THSampleDataProvider

+ (void)loadAudioSamplesFromAsset:(AVAsset *)asset completionBlock:(THSampleDataCompletionBlock)completionBlock {
    
    NSString *tracks = @"tracks";
    
    //对资源所需的键进行标准的异步载入操作
    [asset loadValuesAsynchronouslyForKeys:@[tracks] completionHandler:^{
        
        AVKeyValueStatus status = [asset statusOfValueForKey:tracks error:nil];
        
        NSData *sampleData = nil;
        
        //如果tracks载入成功
        if (status == AVKeyValueStatusLoaded) {
            sampleData = [self readAudioSamplesFromAsset:asset];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(sampleData);
        });
    }];
    
}

//从资源轨道中读取样本
+ (NSData *)readAudioSamplesFromAsset:(AVAsset *)asset {
    
    NSError *error = nil;
    
    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    
    if (!assetReader) {
        NSLog(@"Error creating asset reader: %@", [error localizedDescription]);
        return nil;
    }
    
    //获取资源中找到的第一个音频轨道
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    /*
     *从资源轨道读取音频样本时使用的解压设置
     *kAudioFormatLinearPCM 样本需要以未压缩的格式被读取
     *little-endian字节序(小端序)
     *有符号整型
     *16位
     */
    NSDictionary *outputSettings = @{
        AVFormatIDKey               : @(kAudioFormatLinearPCM),
        AVLinearPCMIsBigEndianKey   : @NO,
		AVLinearPCMIsFloatKey		: @NO,
		AVLinearPCMBitDepthKey		: @(16)
    };
    
    //创建trackOutput，作为AVAssetReader的输出
    AVAssetReaderTrackOutput *trackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:track outputSettings:outputSettings];
    [assetReader addOutput:trackOutput];
    //开始预收取样本数据
    [assetReader startReading];
    
    NSMutableData *sampleData = [NSMutableData data];
    
    while (assetReader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef sampleBuffer = [trackOutput copyNextSampleBuffer];
        
        if (sampleBuffer) {
            //获取音频样本
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
            //确定长度，并创建一个16位的带符号的整型数组来保存音频赝本
            size_t length = CMBlockBufferGetDataLength(blockBufferRef);
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, sampleBytes);
            //数组内容附加在NSData实例后
            [sampleData appendBytes:sampleBytes length:length];
            
            //指定样本buffer已经处理和不可再继续使用
            CMSampleBufferInvalidate(sampleBuffer);
            CFRelease(sampleBuffer);
        }
    }
    
    //数据读取成功
    if (assetReader.status == AVAssetReaderStatusCompleted) {
        return sampleData;
    } else {
        NSLog(@"Failed to read audio samples from asset");
        return nil;
    }
}

@end
