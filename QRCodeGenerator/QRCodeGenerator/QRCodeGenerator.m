//
//  QRCodeGenerator.m
//  QRCodeGenerator
//
//  Created by wangzhen on 17/6/23.
//  Copyright © 2017年 wz. All rights reserved.
//

#import "QRCodeGenerator.h"

@implementation QRCodeGenerator

+ (UIImage *) resizeImageWithoutInterpolation:(UIImage *)sourceImage size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationNone);
    [sourceImage drawInRect:(CGRect){.size = size}];
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return result;
}

+ (UIImage *) imageWithCIImage: (CIImage *) aCIImage orientation: (UIImageOrientation) anOrientation
{
    if (!aCIImage) return nil;
    
    CGImageRef imageRef = [[CIContext contextWithOptions:nil] createCGImage:aCIImage fromRect:aCIImage.extent];
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:anOrientation];
    CFRelease(imageRef);
    
    return image;
}

+ (UIImage *)QRImageWithString:(NSString *) string size:(CGSize)destSize;
{
    //创建filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    if (!qrFilter)
    {
        NSLog(@"Error: Could not load filter");
        return nil;
    }
    
    // 设置 correction level
    // L 7% , M 15% , Q 25% , H 30%
    [qrFilter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    //设置输入的text
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    
    //获取输出的image
    CIImage *outputImage = [qrFilter valueForKey:@"outputImage"];
    
    UIImage *smallImage = [self imageWithCIImage:outputImage orientation: UIImageOrientationUp];
    
    return [self resizeImageWithoutInterpolation:smallImage size:destSize];
}

@end
