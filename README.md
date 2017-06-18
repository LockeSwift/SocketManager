# SocketManager
### iOS 原生Socket和CocoaAsyncSocket框架的简单使用

#### 一、`Socket`到底是什么？
##### 1、`Socket`原理
###### 1.1、`套接字（Socket）`概念
`套接字（Socket）`是通信的基石，是支持`TCP/IP` 或者`UDP/IP`协议的网络通信的基本操作单元／编程接口（如下图）。它是网络通信过程中端点的抽象表示，包含进行网络通信必须的五种信息：`连接使用的协议`，`本地主机的IP地址`，`本地进程的协议端口`，`远地主机的IP地址`，`远地进程的协议端口`。
![](http://upload-images.jianshu.io/upload_images/937459-63be09c50d7bc451.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
###### 1.2、给套接字赋予地址
依照建立套接字的目的不同，赋予套接字地址的方式有两种：服务器端使用`bind`，客户端使用`connect`。
`bind`:给服务器端中的套接字赋予通信的地址和端口，`IP`和`Port`便可以区分一个`TCP/IP`链接通道，如果要区分特定的主机间链接，还需要提供`Hostname`。
`connect`:客户端向特定网络地址的服务器发送连接请求。
###### 1.3、建立`Socket`连接
建立`Socket`连接至少需要一对套接字，其中一个运行于客户端，称为`ClientSocket`，另一个运行于服务器端，称为`ServerSocket`。
套接字之间的连接过程分为三个步骤：`服务器监听（bind、listen）`，`客户端请求（connect）`，`连接确认（accept）`。
###### 1.4`TCP`连接
创建`Socket`链接时，可以制定不同的传输层协议（`TCP`或`UDP`），当使用`TCP`协议进行链接时，该`Socket`链接便是`TCP`链接。
###### TCP连接建立（三次握手）----客户端执行`connect`触发
（1）第一次握手：`Client`将标志位`SYN`置为`1`，随机产生一个值`seq=J`，并将该数据包发送给`Server`，`Client`进入`SYN_SENT`状态，等待`Server`确认。
（2）第二次握手：`Server`收到数据包后由标志位`SYN=1`知道`Client`请求建立连接，`Server`将标志位`SYN`和`ACK`都置为`1`，`ack=J+1`，随机产生一个值`seq=K`，并将该数据包发送给`Client`以确认连接请求，`Server`进入`SYN_RCVD`状态。
（3）第三次握手：`Client`收到确认后，检查`ack`是否为`J+1`，`ACK`是否为`1`，如果正确则将标志位`ACK`置为`1`，`ack=K+1`，并将该数据包发送给`Server`，`Server`检查`ack`是否为`K+1`，`ACK`是否为`1`，如果正确则连接建立成功，`Client`和`Server`进入`ESTABLISHED`状态，完成三次握手，随后`Client`与`Server`之间可以开始传输数据了。
![三次握手](http://upload-images.jianshu.io/upload_images/937459-04e7cad226c56751.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
###### TCP连接终止（四次挥手）----客户端或服务端执行`close`触发
（1）第一次挥手：`Client`发送一个`FIN`，用来关闭`Client`到`Server`的数据传送，`Client`进入`FIN_WAIT_1`状态。
（2）第二次挥手：`Server`收到`FIN`后，发送一个`ACK`给`Client`，确认序号为收到序号`+1`（与`SYN`相同，一个`FIN`占用一个序号），`Server`进入`CLOSE_WAIT`状态。
（3）第三次挥手：`Server`发送一个`FIN`，用来关闭`Server`到`Client`的数据传送，`Server`进入`LAST_ACK`状态。
（4）第四次挥手：`Client`收到`FIN`后，`Client`进入`TIME_WAIT`状态，接着发送一个`ACK`给`Server`，确认序号为收到序号`+1`，`Server`进入`CLOSED`状态，完成四次挥手。
![四次挥手](http://upload-images.jianshu.io/upload_images/937459-728fd3fcf37e97a6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
##### 2、客户端／服务器端模式的理解
首先服务器先启动对端口的监听，等待客户端的链接请求。
###### 服务器端：
（1）服务器调用`socket`创建`Socket`；
（2）服务器调用`listen`设置缓冲区；
（3）服务器通过`accept`接受客户端请求建立连接；
（4）服务器与客户端建立连接之后，就可以通过`send`/`receive`向客户端发送或从客户端接收数据；
（5）服务器调用`close`关闭 `Socket`；
###### 客户端：
（1）客户端调用`socket`创建`Socket`；
（2）客户端调用`connect`向服务器发起连接请求以建立连接；
（3）客户端与服务器建立连接之后，就可以通过`send`/`receive`向客户端发送或从客户端接收数据；
（4）客户端调用`close`关闭`Socket`；
![TCP链接](http://upload-images.jianshu.io/upload_images/937459-be5cd235ca65683e.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
#### 二、基于`C`的`BSD Socket`客户端的实现
##### 1、接口介绍
```
//socket 创建并初始化 socket，返回该 socket 的文件描述符，如果描述符为 -1 表示创建失败。
int socket(int addressFamily, int type,int protocol)
//关闭socket连接
int close(int socketFileDescriptor)
//将 socket 与特定主机地址与端口号绑定，成功绑定返回0，失败返回 -1。
int bind(int socketFileDescriptor,sockaddr *addressToBind,int addressStructLength)
//接受客户端连接请求并将客户端的网络地址信息保存到 clientAddress 中。
int accept(int socketFileDescriptor,sockaddr *clientAddress, int clientAddressStructLength)
//客户端向特定网络地址的服务器发送连接请求，连接成功返回0，失败返回 -1。
int connect(int socketFileDescriptor,sockaddr *serverAddress, int serverAddressLength)
//使用 DNS 查找特定主机名字对应的 IP 地址。如果找不到对应的 IP 地址则返回 NULL。
hostent* gethostbyname(char *hostname)
//通过 socket 发送数据，发送成功返回成功发送的字节数，否则返回 -1。
int send(int socketFileDescriptor, char *buffer, int bufferLength, int flags)
//从 socket 中读取数据，读取成功返回成功读取的字节数，否则返回 -1。
int receive(int socketFileDescriptor,char *buffer, int bufferLength, int flags)
//通过UDP socket 发送数据到特定的网络地址，发送成功返回成功发送的字节数，否则返回 -1。
int sendto(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *destinationAddress, int destinationAddressLength)
//从UDP socket 中读取数据，并保存发送者的网络地址信息，读取成功返回成功读取的字节数，否则返回 -1 。
int recvfrom(int socketFileDescriptor,char *buffer, int bufferLength, int flags, sockaddr *fromAddress, int *fromAddressLength)
```
##### 2、实现
`BSDSocketManager.h`
```
#import <Foundation/Foundation.h>

@interface BSDSocketManager : NSObject
@property (nonatomic, copy) void(^returnStateInformation)(NSString *stateInformation);
+ (instancetype)shareInstance;
- (void)connectToHost:(NSString *)ip port:(NSNumber *)port;
- (void)disConnect;
- (void)sendMessage:(NSString *)message;
```
`BSDSocketManager.m`
```
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
```
#### 三、基于`Socket`原生的`CocoaAsyncSocket`客户端的实现
`GCDSocketManager.h`
```
#import <Foundation/Foundation.h>

@interface GCDSocketManager : NSObject

@property (nonatomic, copy) void(^returnStateInformation)(NSString *stateInformation);
+ (instancetype)shareInstance;
- (BOOL)connectToHost:(NSString *)ip port:(NSNumber *)port;
- (void)disConnect;
- (void)sendMessage:(NSString *)message;

@end
```
`GCDSocketManager.m`
```
#import "GCDSocketManager.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface GCDSocketManager ()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *client;

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
    
    [self.client readDataToLength:sizeof(int) withTimeout:-1 tag:0];
    self.fileLength = 0;
    
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
//发送分段消息成功的回调
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
}
//为上一次设置的发送数据代理续时 (如果设置超时为-1，则永远不会调用到)
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    self.returnStateInformation([NSString stringWithFormat:@"来延时，tag:%ld,elapsed:%f,length:%ld",tag,elapsed,length]);
    return 10;
}

//收到消息的回调
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
        //再次开启
        [self.client readDataToLength:sizeof(int) withTimeout:-1 tag:0];
        self.fileLength = 0;
    }
}
//收到分段消息的回调
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    self.returnStateInformation([NSString stringWithFormat:@"%lu",(unsigned long)partialLength]);
}
//为上一次设置的读取数据代理续时 (如果设置超时为-1，则永远不会调用到)
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    self.returnStateInformation([NSString stringWithFormat:@"来延时，tag:%ld,elapsed:%f,length:%ld",tag,elapsed,length]);
    return 10;
}


@end
```
#### 四、基于`CocoaAsyncSocket`Mac服务器的实现
`GCDSocketManager.h`
```
#import <Foundation/Foundation.h>

@interface GCDSocketManager : NSObject

@property (nonatomic, copy) void(^returnStateInformation)(NSString *stateInformation);

+ (instancetype)shareInstance;
- (BOOL)acceptOnPort:(NSNumber *)port;
- (void)disConnect;
- (void)sendMessage:(NSString *)message;

@end
```
`GCDSocketManager.m`
```
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
```
