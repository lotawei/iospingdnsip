//
//  DetaileViewController.m
//  网络准备
//
//  Created by lotawei on 16/10/19.
//  Copyright © 2016年 lotawei. All rights reserved.
//

#import "DetaileViewController.h"
#import "STDebugFoundation.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "AFHTTPSessionManager.h"
#import "STDPingServices.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>
#include <unistd.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_icmp.h>
#include <netdb.h>
#include <setjmp.h>
#include <errno.h>
#include <sys/time.h>
#import <netinet/udp.h>
#define PACKET_SIZE 4096
#define MAX_WAIT_TIME   5
#define MAX_NO_PACKETS  10000
#define SRCPORT         9050	// UDP packet source port
#define DSTPORT         58127	// UDP packet destination port
#define MAX_TTL         64       // Max hop
#define UDPPACKET_SIZE  40
#define MAXPACKET       65535	// Max size of IP packet


char *addr[100];
char sendpacket[PACKET_SIZE];
char recvpacket[PACKET_SIZE];
int sockfd,datalen = 56;
int nsend = 0, nreceived = 0;
double temp_rtt[MAX_NO_PACKETS];
double all_time = 0;
double min = 0;
double max = 0;
double avg = 0;
double mdev = 0;

struct sockaddr_in dest_addr;
struct sockaddr_in from;
struct timeval tvrecv;
pid_t pid;

//void statistics(int sig);
void send_packet(void);
void recv_packet(void);
//void computer_rtt(void);
void tv_sub(struct timeval *out,struct timeval *in);
int pack(int pack_no);
int unpack(char *buf,int len);
unsigned short cal_checksum(unsigned short *addr,int len);
@interface DetaileViewController ()<UITextFieldDelegate>
{
 
    //用于改变  文字显示
    BOOL    isping ;
    //用于取消未执行完的子线程任务
    
    
    BOOL    shouldcancle;
    
    
    //
    long  long   lastdata;
    

}
@property(nonatomic,strong)STDebugTextView   *atextview;
@property(nonatomic,weak) NSTimer   *timer;
@property(nonatomic,strong) UITextField   *inputtext;
@property(nonatomic,strong) UIButton    *btnping;
@property(nonatomic,strong) STDPingServices   *pingServices;

@end

@implementation DetaileViewController

-(UIButton *)btnping{
    
    if (_btnping == nil) {
        _btnping = [[UIButton  alloc]initWithFrame:CGRectMake(205, 70, 60, 30)];
        _btnping.backgroundColor = [UIColor blackColor];
        [_btnping setTintColor:[UIColor  blueColor]];
        [_btnping setTitle:@"ping" forState:UIControlStateNormal];
    }
    return _btnping;
    
    
}
-(UITextField *)inputtext{
    
    if (_inputtext == nil) {
        
        _inputtext = [[UITextField  alloc]initWithFrame:CGRectMake(0, 65, 200, 40)];
        _inputtext.borderStyle = UITextBorderStyleRoundedRect;
        _inputtext.keyboardType = UIKeyboardTypeURL;
        _inputtext.delegate = self;
       _inputtext.placeholder = @"请输入IP地址或者域名";
        _inputtext.text =  @"www.baidu.com";
    }
    return _inputtext;
    
    
}

-(UITextView *)atextview{
    
    if (_atextview == nil) {
        _atextview =  [[STDebugTextView  alloc]initWithFrame:CGRectMake(0, 400, 375, 300)];
        _atextview.layer.borderColor =[UIColor  blackColor].CGColor;
        _atextview.textAlignment = NSTextAlignmentLeft;
        _atextview.layer.borderWidth = 3.0;
        _atextview.backgroundColor = [UIColor  clearColor];
        _atextview.font = [UIFont  systemFontOfSize:10];\
        
        _atextview.center = self.view.center;
    
    }
    return _atextview;
}
-(instancetype)initWithop:(NSString *)op{
    self = [super init];
    
    self.currentoption = op;
    return self;
}

-(void)changetext:(NSNotification*)noti{
    
    
    
    self.atextview.text = noti.object;
    
    
}
//这里  处理  ping操作耗时 如果直接点击back  需要手动将其只为nil 才能正常调用dealloc
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:NO];
    if(self.pingServices  != nil){
    [self.pingServices cancel];
    self.pingServices = nil;
    }
    //timer使用要注意的地方 不能在dealloc中释放说说
     //原因： timer加到runloop中会对self造成强引用，然而dealloc使用了自动管理内存，它必须要让timer为nil
    if(self.timer != nil)
    {
        [self.timer invalidate];
        self.timer = nil;
    }
    
}

-(void)viewDidLoad{
    [super viewDidLoad];
    
    
    lastdata = 0;
//    [[NSNotificationCenter   defaultCenter] removeObserver:self];
    isping = true;
    
    if ([_currentoption isEqualToString:@"网络总流量"]) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(getInternetface) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
    if ([_currentoption isEqualToString:@"ping"]) {
        [self.view addSubview:self.inputtext];
        [self.view  addSubview:self.btnping];
        
        [self.btnping addTarget:self action:@selector(pingaction:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    
   
    
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.atextview];
    
  
  
    [self  apperancetext];
    
}
-(void)pingaction:(UIButton*)sender{

//    NSString   *title = nil;
//    title = isping ? @"stop":@"ping";
//    isping = isping ? false:true;
//    [sender setTitle:title forState:UIControlStateNormal];
    [self.inputtext resignFirstResponder];
    if (isping &&self.pingServices==nil) {
        
        
        
        
        __weak DetaileViewController *weakSelf = self;
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
        isping = false;
        self.pingServices = [STDPingServices startPingAddress:self.inputtext.text callbackHandler:^(STDPingItem *pingItem, NSArray *pingItems) {
            
            NSLog(@"有%@",pingItems);
            if (pingItem.status != STDPingStatusFinished) {
                [weakSelf.atextview appendText:pingItem.description];
            } else {
                [weakSelf.atextview appendText:[STDPingItem statisticsWithPingItems:pingItems]];
                [sender setTitle:@"Ping" forState:UIControlStateNormal];
                isping = true;
                weakSelf.pingServices = nil;
            }
        }];
    } else {
        [self.pingServices cancel];
    }
}

    
    
    
    

-(void)apperancetext{
    
    if ([self.currentoption isEqualToString:@"ip"]) {
          [[NSNotificationCenter   defaultCenter] addObserver:self selector:@selector(changetext:) name:@"ipsuccess" object:nil];
        
        self.atextview.text = @"正在找你的外网ip请稍后.....";
        __weak  DetaileViewController  *tempself = self;
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
             [tempself getWANIIPAdress];
             
         });
        
        
        
    }
    else   if([self.currentoption isEqualToString:@"当前网络情况"]){
        //本身异步的
        //这里必须  在闭包中弱引用 ，  否则不会掉dealloc方法释放
        __weak    DetaileViewController   *tmpself = self;
        
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            NSString   *str = [NSString  stringWithFormat:@"当前网络状态:%@",AFStringFromNetworkReachabilityStatus(status)] ;
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    tmpself.atextview.text = str;
                });
        }];
        
        [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    }
    else  if([self.currentoption isEqualToString:@"网速测试"])
    {
        
    }
    else  if([self.currentoption isEqualToString:@"dhcp"])
    {
        //测试timer
        
        
        
        
        
    }
    else  if([self.currentoption  isEqualToString:@"主流网站ping测试"]){

//        
//        self.atextview.text  = [STDPingServices  statisticsWithPingItems:pingitems ];
        
        self.atextview.frame = CGRectMake(0, 65, 375, 300);
        
        
    }
    
    else   if  ([self.currentoption   isEqualToString:@"域名解析"])
    {
        
        UITextField    *domin = [[UITextField   alloc]initWithFrame:CGRectMake(0, 65, 200, 40)];
        domin.borderStyle = UITextBorderStyleBezel;
        
        domin.text = @"www.baidu.com";
        
        
        [self.view addSubview:domin];
        
        
        
        self.atextview.text =  [self  queryIpWithDomain:domin.text] ==nil ?   @"解析错误": [self  queryIpWithDomain:domin.text] ;
        
    }
    else if ([self.currentoption  isEqualToString:@"html网站ip解析"]){
        
        UITextField    *domin = [[UITextField   alloc]initWithFrame:CGRectMake(0, 65, 200, 40)];
        domin.borderStyle = UITextBorderStyleBezel;
        
        domin.text = @"http://blog.csdn.net/huayu_huayu/article/details/51198756";
        
        
        [self.view addSubview:domin];
        
        
        
        self.atextview.text =  [self   whatismyipdotcom:[NSURL  URLWithString:domin.text]];
        
    }
    else   if  ([self.currentoption   isEqualToString:@"dns"])
    {
        
      
        
        
        
        self.atextview.text =  @"";
    }
    
    
    
    
}
// 网站域名
- (NSString *)whatismyipdotcom:(NSURL *)ipURL
{
    NSError *error;

    NSString *ip = [NSString stringWithContentsOfURL:ipURL encoding:1 error:&error];
    
    NSRange range = [ip rangeOfString:@"<center>ÄúµÄIPÊÇ£º["];
    NSString *str = @"<center>ÄúµÄIPÊÇ£º[";
    if (range.location > 0 && range.location < ip.length)
    {
        range.location += str.length ;
        range.length = 17;
        ip = [ip substringWithRange:range];
        
        range = [ip rangeOfString:@"]"];
        range.length = range.location;
        range.location = 0;
        ip = [ip substringWithRange:range];
    }
    
    return ip ? ip : nil;
}

//域名-》ip

-(NSString *)queryIpWithDomain:(NSString *)domain
{
    struct hostent *hs;
    struct sockaddr_in server;
    if ((hs = gethostbyname([domain UTF8String])) != NULL)
    {
        server.sin_addr = *((struct in_addr*)hs->h_addr_list[0]);
        return [NSString stringWithUTF8String:inet_ntoa(server.sin_addr)];
    }
    return nil;
}

//获取dhcp服务器
-(id)getSSIDInfo
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@",info);
        if (info && [info count]) {
            break;
        }
    }
    return info;
}
//得到联网线时本机地址
- (NSString *)getLANIIPAdress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0) {
        temp_addr = interfaces;
        while (temp_addr !=NULL) {
            if (temp_addr->ifa_addr->sa_family==AF_INET) {
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    
    return address;
}
//外网
- (NSString *)getWANIIPAdress
{
    NSString *IP = @"0.0.0.0";
    NSURL *url = [NSURL URLWithString:@"http://ifconfig.me/ip"];
    
    
      NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    
    NSURLResponse *response = nil;
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    
    
    if (error) {
//        MyLog(@"Failed to get WAN IP Address!\n%@", error);
        
              dispatch_async(dispatch_get_main_queue(), ^{
                  [[[UIAlertView alloc] initWithTitle:@"获取外网 IP 地址失败" message:[error localizedFailureReason] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
              });
    } else {
        NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        IP = responseStr;
        //如何进行回调呢  发个通知吧,也可以使用 上层封装一个block  在这里就可以进行回调，这里使用通知简单处理
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter   defaultCenter] postNotificationName:@"ipsuccess" object:IP];
        });
        
    }
  
    
    
    
    return IP;
}

//获取流量   并计算大致当前流量情况
- (void)getInternetface {
    long  long   churu = 0;
    long long re = [self getInterfaceBytes];
//    long  long  wa = hehe/1024/1024/1024;
    if (lastdata != 0) {
        churu = re - lastdata;
    }
    
    NSString   *liuliang = [NSString  stringWithFormat:@"当前网卡总流量:%lld kb\n",re];
    
   
    NSString   *result = [liuliang stringByAppendingString:[NSString  stringWithFormat:@"大致流量出入:%lld kb/s",churu]];
    
    self.atextview.text = result;
    lastdata = re;
}



/*获取网络总 的流量信息*/

- (long long) getInterfaceBytes

{
    
    struct ifaddrs *ifa_list = 0, *ifa;
    
    if (getifaddrs(&ifa_list) == -1)
        
    {
        
        return 0;
        
    }
    
    
    
    uint32_t iBytes = 0;
    
    uint32_t oBytes = 0;
    
    
    
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
        
    {
        
        if (AF_LINK != ifa->ifa_addr->sa_family)
            
            continue;
        
        
        
        if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
            
            continue;
        
        
        
        if (ifa->ifa_data == 0)
            
            continue;
        
        
        
        /* Not a loopback device. */
        
        if (strncmp(ifa->ifa_name, "lo", 2))
            
        {
            
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            
            
            
            iBytes += if_data->ifi_ibytes;
            
            oBytes += if_data->ifi_obytes;
            
        }
        
    }
    
    freeifaddrs(ifa_list);
    
    
    
    
    return iBytes + oBytes;
    
}

//获取网络流量

- (NSArray *)getDataCounters

{
    
    BOOL   success;
    
    struct ifaddrs *addrs;
    
    const struct ifaddrs *cursor;
    
    const struct if_data *networkStatisc;
    
    
    
    int WiFiSent = 0;
    
    int WiFiReceived = 0;
    
    int WWANSent = 0;
    
    int WWANReceived = 0;
    
    
    
    NSString *name=[[NSString alloc]init];
    
    
    
    success = getifaddrs(&addrs) == 0;
    
    if (success)
        
    {
        
        cursor = addrs;
        
        while (cursor != NULL)
            
        {
            
            
            
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            NSLog(@"ifa_name %s == %@n", cursor->ifa_name,name);
            
            // names of interfaces: en0 is WiFi ,pdp_ip0 is WWAN
            
            
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
                
            {
                
                if ([name hasPrefix:@"en"])
                    
                {
                    
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    
                    WiFiSent+=networkStatisc->ifi_obytes;
                    
                    WiFiReceived+=networkStatisc->ifi_ibytes;
                    
                    // NSLog(@"WiFiSent %d ==%d",WiFiSent,networkStatisc->ifi_obytes);
                    
                    //NSLog(@"WiFiReceived %d ==%d",WiFiReceived,networkStatisc->ifi_ibytes);
                    
                }
                
                
                
                if ([name hasPrefix:@"pdp_ip"])
                    
                {
                    
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    
                    WWANSent+=networkStatisc->ifi_obytes;
                    
                    WWANReceived+=networkStatisc->ifi_ibytes;
                    
                    // NSLog(@"WWANSent %d ==%d",WWANSent,networkStatisc->ifi_obytes);
                    
                    //NSLog(@"WWANReceived %d ==%d",WWANReceived,networkStatisc->ifi_ibytes);
                    
                    
                    
                }
                
            }
            
            
            
            cursor = cursor->ifa_next;
            
        }
        
        
        
        freeifaddrs(addrs);
        
    }       
    
    
    
    NSLog(@"nwifiSend:%.2f MBnwifiReceived:%.2f MBn wwansend:%.2f MBn wwanreceived:%.2f MBn",WiFiSent/1024.0/1024.0,WiFiReceived/1024.0/1024.0,WWANSent/1024.0/1024.0,WWANReceived/1024.0/1024.0);
    
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:WiFiSent], [NSNumber numberWithInt:WiFiReceived],[NSNumber numberWithInt:WWANSent],[NSNumber numberWithInt:WWANReceived], nil];
    
}
-(void)dealloc{
    NSLog(@"ddddddd");
    
    
    
    [[NSNotificationCenter   defaultCenter] removeObserver:self];
    
    
}




@end
