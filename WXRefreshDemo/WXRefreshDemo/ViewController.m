//
//  ViewController.m
//  WXRefreshDemo
//
//  Created by psw on 2018/1/5.
//  Copyright © 2018年 shaowu. All rights reserved.
//

#import "ViewController.h"
#import "FirstViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *jumpBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    jumpBtn.frame = CGRectMake(30, 100, 100, 35);
    [jumpBtn setTitle:@"进入控制器" forState:UIControlStateNormal];
    [jumpBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [jumpBtn setBackgroundColor:[UIColor redColor]];
    [jumpBtn addTarget:self action:@selector(jump) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:jumpBtn];
}

- (void)jump
{
    FirstViewController *firstVc = [[FirstViewController alloc] init];
    [self.navigationController pushViewController:firstVc animated:YES];
}

@end
