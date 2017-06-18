//
//  BSDSocketManager.m
//  Socket的使用
//
//  Created by Locke on 2017/6/14.
//  Copyright © 2017年 lainkai. All rights reserved.
//
/**
 导入头文件：<arpa/inet.h>，<netdb.h>
 
 1. socket 创建并初始化 socket，返回该 socket 的文件描述符，如果描述符为 -1 表示创建失败。
 int socket(int addressFamily, int type,int protocol)
 
 2. 关闭socket连接
 int close(int socketFileDescriptor)
 
 3. 将 socket 与特定主机地址与端口号绑定，成功绑定返回0，失败返回 -1。
 int bind(int socketFileDescriptor,sockaddr *addressToBind,int addressStructLength)
 
 4. 接受客户端连接请求并将客户端的网络地址信息保存到 clientAddress 中。
 int accept(int socketFileDescriptor,sockaddr *clientAddress, int clientAddressStructLength)
 
 5. 客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
 int connect(int socketFileDescriptor,sockaddr *serverAddress, int serverAddressLength)
 
 6. 使用 DNS 查找特定主机名字对应的 IP 地址。如果找不到对应的 IP 地址则返回 NULL。
 hostent* gethostbyname(char *hostname)
 
 7. 通过 socket 发送数据，发送成功返回成功发送的字节数，否则返回 -1。
 int send(int socketFileDescriptor, char *buffer, int bufferLength, int flags)
 
 8. 从 socket 中读取数据，读取成功返回成功读取的字节数，否则返回 -1。
 int receive(int socketFileDescriptor,char *buffer, int bufferLength, int flags)
 
 9. 通过UDP socket 发送数据到特定的网络地址，发送成功返回成功发送的字节数，否则返回 -1。
 int sendto(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *destinationAddress, int destinationAddressLength)
 
 10. 从UDP socket 中读取数据，并保存发送者的网络地址信息，读取成功返回成功读取的字节数，否则返回 -1 。
 int recvfrom(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *fromAddress, int *fromAddressLength)
 */
#import "BSDSocketManager.h"
#import <arpa/inet.h>
#import <netdb.h>

@interface BSDSocketManager ()

@property (nonatomic, assign) int socketFileDescriptor;
@property (nonatomic, assign, getter=isCanRecieveMessage) BOOL canRecieveMessage;

@end

@implementation BSDSocketManager

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BSDSocketManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}
#pragma mark - 连接
- (void)connectToHost:(NSString *)ip port:(NSNumber *)port {
    //每次链接前，先断开连接
    if (self.socketFileDescriptor != 0) {
        [self disConnect];
        self.socketFileDescriptor = 0;
    }
    
    /**创建客户端socket
     创建一个socket，返回值为int。(socket类型就是int类型)
     第一个参数(addressFamily): IPv4(AF_INET) 或者 IPv6(AF_INET6)
     第二个参数(type): socket类型，通常是流stream(SOCK_STREAM) 或数据报文datagram(SOCK_DGRAM)
     第三个参数(protocol): 通常设置为0，以便让系统自动为选择我们合适的协议，对于 stream socket 来说会是 TCP 协议(IPPROTO_TCP)，而对于 datagram来说会是 UDP 协议(IPPROTO_UDP)
     */
    self.socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
    if (self.socketFileDescriptor == -1) {
        NSLog(@"创建链接失败");
        return;
    }
    
    //设置sockaddr_in结构体
    struct sockaddr_in socketParameters = {0};
    socketParameters.sin_len = sizeof(socketParameters);
    //设置IPv4
    socketParameters.sin_family = AF_INET;
    
    //使用 DNS 查找特定主机名字对应的 IP 地址
    struct hostent *remoteHostEnt = gethostbyname([ip UTF8String]);
    if (remoteHostEnt == NULL) {
        [self disConnect];
        NSLog(@"找不到IP地址");
        return;
    }
    struct in_addr *remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
    socketParameters.sin_addr = *remoteInAddr;
    
    
    //htons是将整形变量从主机字节顺序转变成网络字节顺序，赋值端口号
    socketParameters.sin_port = htons([port intValue]);
    
    /**用scoket和服务端地址，发起连接
     客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
     注意：该接口调用会阻塞当前线程，直到服务器返回。
     */
    int ret = connect(self.socketFileDescriptor, (struct sockaddr *)&socketParameters, sizeof(socketParameters));
    if (ret == -1) {
        [self disConnect];
        NSLog(@"连接失败");
        return;
    }
    NSLog(@"连接成功");
    self.canRecieveMessage = YES;
    [self recieveMessage];
}
#pragma mark - 断开链接
- (void)disConnect {
    //关闭连接
    int ret = close(self.socketFileDescriptor);
    if (ret == -1) {
        NSLog(@"断开链接失败");
        return;
    }
    NSLog(@"断开链接成功");
    self.canRecieveMessage = NO;
}
#pragma mark - 发送消息
- (void)sendMessage:(NSString *)message {
    const char *sendMessage = [message UTF8String];
    ssize_t ret =  send(self.socketFileDescriptor, sendMessage, strlen(sendMessage) + 1, 0);
    if (ret == -1) {
        NSLog(@"发送失败");
        return;
    }
    NSLog(@"发送成功");
}
#pragma mark - 接收服务器发送的消息
- (void)recieveMessage {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __weak typeof(self) weak_Self = self;
        [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
            __strong typeof(weak_Self) self = weak_Self;
            char revieveMessage[1024] = {0};
            if (recv(self.socketFileDescriptor, revieveMessage, sizeof(revieveMessage), 0) != -1) {
                NSLog(@"接收到消息：%s", revieveMessage);
            }
        }];
        while (self.isCanRecieveMessage) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
    });
}

@end
