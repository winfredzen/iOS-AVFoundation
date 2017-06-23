//
//  ViewController.m
//  QRCodeGenerator
//
//  Created by wangzhen on 17/6/23.
//  Copyright © 2017年 wz. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeGenerator.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textfield;
- (IBAction)generateQRCode:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)generateQRCode:(id)sender {
    [_textfield resignFirstResponder];
    self.imageView.image = [QRCodeGenerator QRImageWithString:_textfield.text size:CGSizeMake(300, 300)];
}
@end
