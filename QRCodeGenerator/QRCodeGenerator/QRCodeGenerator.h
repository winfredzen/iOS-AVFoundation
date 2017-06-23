//
//  QRCodeGenerator.h
//  QRCodeGenerator
//
//  Created by wangzhen on 17/6/23.
//  Copyright © 2017年 wz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface QRCodeGenerator : NSObject

+ (UIImage *)QRImageWithString:(NSString *) string size:(CGSize)destSize;

@end
