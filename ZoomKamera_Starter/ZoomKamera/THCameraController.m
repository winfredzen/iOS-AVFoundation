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

#import "THCameraController.h"
#import <AVFoundation/AVFoundation.h>

const CGFloat THZoomTime = 1.0f;

// KVO Contexts
static const NSString *THRampingVideoZoomContext;
static const NSString *THRampingVideoZoomFactorContext;

@implementation THCameraController

- (BOOL)setupSessionInputs:(NSError **)error {
    BOOL success = [super setupSessionInputs:error];
    if (success) {
        [self.activeCamera addObserver:self forKeyPath:@"videoZoomFactor" options:0 context:&THRampingVideoZoomFactorContext];
        [self.activeCamera addObserver:self forKeyPath:@"rampingVideoZoom" options:0 context:&THRampingVideoZoomContext];
    }
    return success;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == &THRampingVideoZoomContext) {
        [self updateZoomingDelegate];
    } else if (context == &THRampingVideoZoomFactorContext) {
        if (self.activeCamera.isRampingVideoZoom) {
            [self updateZoomingDelegate];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)updateZoomingDelegate {
    CGFloat curZoomFactor = self.activeCamera.videoZoomFactor;
    CGFloat maxZoomFactor = [self maxZoomFactor];
    CGFloat value = log(curZoomFactor) / log(maxZoomFactor);
    [self.zoomingDelegate rampedZoomToValue:value];
}

//是否支持缩放
- (BOOL)cameraSupportsZoom {
    return self.activeCamera.activeFormat.videoMaxZoomFactor > 1.0f;
}

//最大缩放因子
- (CGFloat)maxZoomFactor {
    return MIN(self.activeCamera.activeFormat.videoMaxZoomFactor, 4.0f);
}

- (void)setZoomValue:(CGFloat)zoomValue {

    //A Boolean value that indicates whether a zoom transition is in progress.
    if (!self.activeCamera.isRampingVideoZoom) {
        NSError *error;
        if ([self.activeCamera lockForConfiguration:&error]) {
            
            CGFloat zoomFactor = pow([self maxZoomFactor], zoomValue);
            self.activeCamera.videoZoomFactor = zoomFactor;
            
            [self.activeCamera unlockForConfiguration];
            
        }else{
            [self.delegate deviceConfigurationFailedWithError:error];
        }
    }
    
}

- (void)rampZoomToValue:(CGFloat)zoomValue {

    CGFloat zoomFactor = pow([self maxZoomFactor], zoomValue);
    NSError *error;
    if ([self.activeCamera lockForConfiguration:&error]) {
        [self.activeCamera rampToVideoZoomFactor:zoomFactor withRate:THZoomTime];
        [self.activeCamera unlockForConfiguration];
    }else{
        [self.delegate deviceConfigurationFailedWithError:error];
    }

}

- (void)cancelZoom {

    NSError *error;
    if ([self.activeCamera lockForConfiguration:&error]) {
        [self.activeCamera cancelVideoZoomRamp];
        [self.activeCamera unlockForConfiguration];
    }else{
        [self.delegate deviceConfigurationFailedWithError:error];
    }

}


@end

