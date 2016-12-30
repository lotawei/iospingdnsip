//
//  ViewController.m
//  网络准备
//
//  Created by lotawei on 16/10/19.
//  Copyright © 2016年 lotawei. All rights reserved.
//

#import "ViewController.h"
#import "DetaileViewController.h"
#import "AFNetworking.h"
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)   UITableView   *tableview;
@property(nonatomic,strong) NSArray    *arr;
@end


@implementation ViewController

-(NSArray *)arr{
    
    
    
    
    return   @[@"ping",@"ip",@"dns",@"当前网络情况",@"dhcp",@"网速测试",@"上传至服务器",@"网络总流量",@"主流网站ping测试",@"域名解析",@"html网站ip解析"];
}

-(UITableView *)tableview{
    
    if (_tableview== nil) {
        _tableview  = [[UITableView  alloc]initWithFrame:CGRectMake(0, 0, 375, 611) style:UITableViewStylePlain];
        
        
    }
    return _tableview;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableview];
    self.tableview.delegate = self;
    
    self.tableview.dataSource=self;
    
    
    
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return   self.arr.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell   *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    
    if (cell == nil) {
      cell = [[UITableViewCell  alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.arr[indexPath.row];
    
    return   cell;
    
    
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString   *op =  self.arr[indexPath.row];
    
    
    DetaileViewController   *devc =  [[DetaileViewController  alloc]initWithop:op];
    
    [self.navigationController pushViewController:devc animated:true];
    
    
    
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
