//
//  GCDSocketManager.m
//  Mac服务器
//
//  Created by Locke on 2017/6/15.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import "GCDSocketManager.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface GCDSocketManager ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *server;
@property (nonatomic, strong) NSMutableArray *clientArrsSocket;
@property (nonatomic, assign) int fileLength;
@property (nonatomic, strong) NSMutableData *receiveData;

@end

@implementation GCDSocketManager

//读取数据长度
static int readLength = 4;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static GCDSocketManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[GCDSocketManager alloc] init];
    });
    return manager;
}

//创建服务器链接管道
- (GCDAsyncSocket *)server {
    if (!_server) {
        _server  = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _server;
}
- (NSMutableArray *)clientArrsSocket {
    if (!_clientArrsSocket) {
        _clientArrsSocket = [NSMutableArray array];
    }
    return _clientArrsSocket;
}

#pragma mark - <对外接口>
//通过socket  监听\绑定
- (BOOL)acceptOnPort:(NSNumber *)port {
    NSError *error;
    BOOL result = [self.server acceptOnPort:port.intValue error:&error];
    if (!error) {
        self.returnStateInformation([NSString stringWithFormat:@"正在监听：host:%@,port:%d", self.server.localHost, self.server.localPort]);
    } else {
        self.returnStateInformation([NSString stringWithFormat:@"监听失败：error:%@", error.localizedFailureReason]);
    }
    return result;
}
//断开链接
- (void)disConnect {
    [self.server disconnect];
}
//发送消息
- (void)sendMessage:(NSString *)message {
    NSMutableData *sendData = [NSMutableData data];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    int dataLength = (int)[data length];
    NSData *lengthData = [[NSData alloc] initWithBytes:&dataLength length:sizeof(int)];
    [sendData appendData:lengthData];//发送数据长度
    [sendData appendData:data];//发送数据实体
    //第二个参数，请求超时时间
    for (GCDAsyncSocket *newSocket in self.clientArrsSocket) {
        [newSocket writeData:sendData withTimeout:-1 tag:0];
    }
}

#pragma mark - <代理方法>
//新的客户端连接监听的Socket服务器端口
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    //保存newSocket，解决clientsocket是局部变量导致连接关闭的状况
    [self.clientArrsSocket addObject:newSocket];

    self.returnStateInformation([NSString stringWithFormat:@"端口链入：host:%@,port:%d", newSocket.localHost, newSocket.localPort]);
    
    //通过制定newScoket 读取数据（只能读取1条数据)
    [newSocket readDataToLength:sizeof(int) withTimeout:-1 tag:1];
    self.fileLength = 0;
    
    
    //MARK: - 心跳检测写在这...
}

//断开监听
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if ([self.clientArrsSocket containsObject:sock]) {
        [self.clientArrsSocket removeObject:sock];
    }
    
    //MARK: - 断线重连写在这...
}
/**
 int i = 1;
 NSData *data = [NSData dataWithBytes: &i length: sizeof(i)];
 int i;
 [data getBytes: &i length: sizeof(i)];
 */
//接收数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    int fileLength = 0;
    if (self.fileLength == 0) {
        self.receiveData = [NSMutableData data];
        [data getBytes:&fileLength length:sizeof(int)];
        self.fileLength = fileLength;
    }
    if (!fileLength) {
        [self.receiveData appendData:data];
    }
    if ([self.receiveData length] < self.fileLength) {
        int leftoverLength = (int)(self.fileLength - [self.receiveData length]);
        if (leftoverLength < readLength) {
            [sock readDataToLength:leftoverLength withTimeout:-1 tag:1];
        } else {
            [sock readDataToLength:readLength withTimeout:-1 tag:1];
        }
    } else {
        self.returnStateInformation([NSString stringWithFormat:@"接收数据为：%@",[[NSString alloc] initWithData:self.receiveData encoding:NSUTF8StringEncoding]]);
        [sock readDataToLength:sizeof(int) withTimeout:-1 tag:1];
        self.fileLength = 0;
    }
}
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"%lu",(unsigned long)partialLength);
}

//发送消息成功的回调
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    self.returnStateInformation([NSString stringWithFormat:@"发送消息成功：host:%@,port:%d", sock.localHost, sock.localPort]);
}

@end
