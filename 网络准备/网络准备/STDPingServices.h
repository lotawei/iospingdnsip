//
//  STDPingServices.h
//  STKitDemo
//
//  Created by SunJiangting on 15-3-9.
//  Copyright (c) 2015年 SunJiangting. All rights reserved.
//

//思想： 还是利用app  demo 中使用 simpleping  作为属性 去ping 实现其代理
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "STSimplePing.h"

typedef NS_ENUM(NSInteger, STDPingStatus) {
    STDPingStatusDidStart,
    STDPingStatusDidFailToSendPacket,
    STDPingStatusDidReceivePacket,
    STDPingStatusDidReceiveUnexpectedPacket,
    STDPingStatusDidTimeout,
    STDPingStatusError,
    STDPingStatusFinished,
};

@interface STDPingItem : NSObject

//目标原地址
@property(nonatomic) NSString *originalAddress;
//目标ip地址   32个bit ip
@property(nonatomic, copy) NSString *IPAddress;
//数据长度
@property(nonatomic) NSUInteger dateBytesLength;
//回应时间
@property(nonatomic) double     timeMilliseconds;
//ttl请求生命周期，路由跳转  可以重这里看出 不同系统有默认值 - 当前这个ttl 就是路由周转跳数
@property(nonatomic) NSInteger  timeToLive;
//路由跳数

@property(nonatomic) NSInteger   tracertCount;
@property(nonatomic) NSInteger  ICMPSequence;

@property(nonatomic) STDPingStatus status;

+ (NSString *)statisticsWithPingItems:(NSArray *)pingItems;

@end

@interface STDPingServices : NSObject

/// 超时时间, default 500ms
@property(nonatomic) double timeoutMilliseconds;

+ (STDPingServices *)startPingAddress:(NSString *)address
                      callbackHandler:(void(^)(STDPingItem *pingItem, NSArray *pingItems))handler;









@property(nonatomic) NSInteger  maximumPingTimes;













- (void)cancel;

@end
