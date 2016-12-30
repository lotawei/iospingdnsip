//
//  DetaileViewController.h
//  网络准备
//
//  Created by lotawei on 16/10/19.
//  Copyright © 2016年 lotawei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetaileViewController : UIViewController


-(instancetype)initWithop:(NSString *)op;
@property(nonatomic,strong)  NSString   *currentoption;
//获取本地局域网ip地址
- (NSString *)getLANIIPAdress;







@end
