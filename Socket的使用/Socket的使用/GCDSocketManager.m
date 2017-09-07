//
//  GCDSocketManager.m
//  Socket的使用
//
//  Created by Locke on 2017/6/15.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import "GCDSocketManager.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface GCDSocketManager ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *client;
@property (nonatomic, strong) NSMutableData *receiveData;

@end

@implementation GCDSocketManager

//读取数据长度
static int readLength = 4;
static int totalLength;//接收数据总长度

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static GCDSocketManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[GCDSocketManager alloc] init];
    });
    return manager;
}

- (GCDAsyncSocket *)client {
    if (!_client) {
        _client = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    return _client;
}
//建立连接
- (BOOL)connectToHost:(NSString *)ip port:(NSNumber *)port {
    return [self.client connectToHost:ip onPort:port.intValue error:nil];
}
//断开连接
- (void)disConnect {
    [self.client disconnect];
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
    [self.client writeData:sendData withTimeout:-1 tag:0];
}

#pragma mark - <代理方法>
//连接成功的调用
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    self.returnStateInformation([NSString stringWithFormat:@"连接成功,host:%@,port:%d", host, port]);
    
    [self startReceiveData];
    
    //MARK: - 心跳检测写在这...
}

//断开连接的调用
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.returnStateInformation([NSString stringWithFormat:@"断开连接,host:%@,port:%d", sock.localHost, sock.localPort]);
    
    //MARK: - 断线重连写在这...
}

//发送消息成功的回调
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    self.returnStateInformation([NSString stringWithFormat:@"发送消息,host:%@,port:%d", sock.localHost, sock.localPort]);
}

//为上一次设置的发送数据代理续时 (如果设置超时为-1，则永远不会调用到)
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    self.returnStateInformation([NSString stringWithFormat:@"来延时，tag:%ld,elapsed:%f,length:%ld",tag,elapsed,length]);
    return 10;
}
//重启接收数据等待
- (void)startReceiveData {
    totalLength = 0;
    self.receiveData = [NSMutableData data];//每次接收数据前都初始化data
    [self.client readDataToLength:sizeof(int) withTimeout:-1 tag:0];
}

//收到消息的回调
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (!totalLength) {
        [data getBytes:&totalLength length:sizeof(int)];
    } else {
        [self.receiveData appendData:data];
    }
    if (totalLength - self.receiveData.length == 0)  {
        self.returnStateInformation([NSString stringWithFormat:@"接收数据为：%@",[[NSString alloc] initWithData:self.receiveData encoding:NSUTF8StringEncoding]]);
        [self startReceiveData];
    } else if(totalLength - self.receiveData.length < readLength) {
        [sock readDataToLength:totalLength - self.receiveData.length withTimeout:-1 tag:1];
    } else {
        [sock readDataToLength:readLength withTimeout:-1 tag:1];
    }
}
//接收数据长度不符合readDataToLength:设定好的长度时，回调这个方法
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    self.returnStateInformation([NSString stringWithFormat:@"不符合设定长度，此次接收的数据长度为%lu",(unsigned long)partialLength]);
}
//为上一次设置的读取数据代理续时 (如果设置超时为-1，则永远不会调用到)
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    self.returnStateInformation([NSString stringWithFormat:@"来延时，tag:%ld,elapsed:%f,length:%ld",tag,elapsed,length]);
    return 10;
}


@end
