//
//  ViewController.m
//  KDCamera
//
//  Created by qihan02 on 2017/9/18.
//  Copyright © 2017年 kd666. All rights reserved.
//

#import "ViewController.h"
#import "KDRecordViewController.h"

@interface ViewController ()

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

- (IBAction)recordButtonClick:(id)sender {
    KDRecordViewController *ctl = [[KDRecordViewController alloc] init];
    [self presentViewController:ctl animated:YES completion:^{
        
    }];
}

@end
