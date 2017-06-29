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

#import "THSampleDataFilter.h"

@interface THSampleDataFilter ()
@property (nonatomic, strong) NSData *sampleData;
@end

@implementation THSampleDataFilter

- (id)initWithData:(NSData *)sampleData {
    self = [super init];
    if (self) {
        _sampleData = sampleData;
    }
    return self;
}

- (NSArray *)filteredSamplesForSize:(CGSize)size {

    //样本分箱
    NSMutableArray *filteredSamples = [[NSMutableArray alloc] init];
    NSUInteger sampleCount = self.sampleData.length / sizeof(SInt16);
    NSUInteger binSize = sampleCount / size.width;

    SInt16 *bytes = (SInt16 *) self.sampleData.bytes;
    
    SInt16 maxSample = 0;
    
    for (NSUInteger i = 0; i < sampleCount; i += binSize) {

        SInt16 sampleBin[binSize];

        for (NSUInteger j = 0; j < binSize; j++) {
            //Converts a 16-bit integer from little-endian format to the host’s native byte order.
            //确保样本按主机内置的字节顺序处理
			sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
        }
        
        //找到最大样本
        SInt16 value = [self maxValueInArray:sampleBin ofSize:binSize];
        [filteredSamples addObject:@(value)];

        //最大值作为筛选样本所使用的比例因子
        if (value > maxSample) {
            maxSample = value;
        }
    }

    CGFloat scaleFactor = (size.height / 2) / maxSample;

    for (NSUInteger i = 0; i < filteredSamples.count; i++) {  
        filteredSamples[i] = @([filteredSamples[i] integerValue] * scaleFactor);
    }

    return filteredSamples;
}

- (SInt16)maxValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    SInt16 maxValue = 0;
    for (int i = 0; i < size; i++) {
        if (abs(values[i]) > maxValue) {
            maxValue = abs(values[i]);
        }
    }
    return maxValue;
}

@end
