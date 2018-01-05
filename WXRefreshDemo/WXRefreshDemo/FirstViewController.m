//
//  FirstViewController.m
//  WXRefreshDemo
//
//  Created by psw on 2018/1/5.
//  Copyright © 2018年 shaowu. All rights reserved.
//

#import "FirstViewController.h"
#import "UIView+SWRefresh.h"

@interface FirstViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArr;

@end

@implementation FirstViewController

- (NSMutableArray *)dataArr
{
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        _tableView.rowHeight = 60.f;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    
    __weak typeof(self) wself = self;
    [self.view sw_refreshWithObject:self.tableView atPoint:CGPointMake(30.f, -70.f) downRefresh:^{
        [wself requestData];
    }];
    
    [self.view beginRefresh];
}

- (void)requestData
{
    __weak typeof(self) wself = self;
    
    // 模拟数据请求
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wself.view sw_endRefresh];
        NSString *str = nil;
        for (int i = 0; i < 15; i++) {
            str = [NSString stringWithFormat:@"这是第 %zd 行",i];
            [wself.dataArr addObject:str];
        }
        [wself.tableView reloadData];
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (self.dataArr.count) {
        cell.textLabel.text = self.dataArr[indexPath.row];
    }
    return cell;
}

- (void)dealloc
{
    self.tableView.delegate = nil;
    self.tableView.dataSource = nil;
    
    //注意：这里一定要移除观察者，不然可能会崩溃
    [self.view sw_freeReFresh];
}

@end
