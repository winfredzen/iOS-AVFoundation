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

#import "THPreviewView.h"

@interface THPreviewView ()
@property (strong, nonatomic) CALayer *overlayLayer;
@property (strong, nonatomic) NSMutableDictionary *faceLayers;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation THPreviewView

+ (Class)layerClass {
	return [AVCaptureVideoPreviewLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.faceLayers = [NSMutableDictionary dictionary];
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

    self.overlayLayer = [CALayer layer];
    self.overlayLayer.frame = self.bounds;
    self.overlayLayer.sublayerTransform = CATransform3DMakePerspective(1000);
    [self.previewLayer addSublayer:self.overlayLayer];
}

- (AVCaptureSession*)session {
	return self.previewLayer.session;
}

- (void)setSession:(AVCaptureSession *)session {
    self.previewLayer.session = session;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (void)didDetectFaces:(NSArray *)faces {

    NSArray *transformedFaces = [self transformedFacesFromFaces:faces];

    NSMutableArray *lostFaces = [self.faceLayers.allKeys mutableCopy];

    for (AVMetadataFaceObject *face in transformedFaces) {

        NSNumber *faceID = @(face.faceID);
		[lostFaces removeObject:faceID];

        CALayer *layer = [self.faceLayers objectForKey:faceID];
        if (!layer) {
            // no layer for faceID, create new face layer
            layer = [self makeFaceLayer];                                 
            [self.overlayLayer addSublayer:layer];
            self.faceLayers[faceID] = layer;
        }

        layer.transform = CATransform3DIdentity;
        layer.frame = face.bounds;

        //判断人脸对象是否具有有效的倾斜角
        if (face.hasRollAngle) {
            CATransform3D t = [self transformForRollAngle:face.rollAngle];
            layer.transform = CATransform3DConcat(layer.transform, t);
        }

        //询问人脸对象是否有偏转角
        if (face.hasYawAngle) {
            CATransform3D t = [self transformForYawAngle:face.yawAngle];
            layer.transform = CATransform3DConcat(layer.transform, t);
        }
    }

    for (NSNumber *faceID in lostFaces) {
        CALayer *layer = [self.faceLayers objectForKey:faceID];
        [layer removeFromSuperlayer];
        [self.faceLayers removeObjectForKey:faceID];
    }

}

- (NSArray *)transformedFacesFromFaces:(NSArray *)faces {
    NSMutableArray *transformedFaces = [NSMutableArray array];
    for (AVMetadataObject *face in faces) {
        //将设备坐标空间的人脸对象转换为视图空间对象集合
        AVMetadataObject *transformedFace = [self.previewLayer transformedMetadataObjectForMetadataObject:face];
        [transformedFaces addObject:transformedFace];
    }
    return transformedFaces;
}

- (CALayer *)makeFaceLayer {
    CALayer *layer = [CALayer layer];
    layer.borderWidth = 5.0f;
    layer.borderColor = [UIColor colorWithRed:0.188 green:0.517 blue:0.877 alpha:1.000].CGColor;
    return layer;
}

// Rotate around Z-axis
- (CATransform3D)transformForRollAngle:(CGFloat)rollAngleInDegrees {
    CGFloat rollAngleInRadians = THDegreesToRadians(rollAngleInDegrees);
    return CATransform3DMakeRotation(rollAngleInRadians, 0.0f, 0.0f, 1.0f);
}

// Rotate around Y-axis
- (CATransform3D)transformForYawAngle:(CGFloat)yawAngleInDegrees {
    CGFloat yawAngleInRadians = THDegreesToRadians(yawAngleInDegrees);

    CATransform3D yawTransform = CATransform3DMakeRotation(yawAngleInRadians, 0.0f, -1.0f, 0.0f);

    return CATransform3DConcat(yawTransform, [self orientationTransform]);
}

- (CATransform3D)orientationTransform {                                   
	CGFloat angle = 0.0;
	switch ([UIDevice currentDevice].orientation) {
		case UIDeviceOrientationPortraitUpsideDown:
	        angle = M_PI;
	        break;
		case UIDeviceOrientationLandscapeRight:
	        angle = -M_PI / 2.0f;
	        break;
		case UIDeviceOrientationLandscapeLeft:
	        angle = M_PI / 2.0f;
	        break;
		default: // as UIDeviceOrientationPortrait
	        angle = 0.0;
	        break;
	}
	return CATransform3DMakeRotation(angle, 0.0f, 0.0f, 1.0f);
}

static CGFloat THDegreesToRadians(CGFloat degrees) {
    return degrees * M_PI / 180;
}

static CATransform3D CATransform3DMakePerspective(CGFloat eyePosition) {    // 3
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / eyePosition;
    return transform;
}

@end
