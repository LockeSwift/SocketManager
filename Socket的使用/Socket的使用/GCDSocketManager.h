//
//  GCDSocketManager.h
//  Socket的使用
//
//  Created by Locke on 2017/6/15.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GCDSocketManager : NSObject

@property (nonatomic, copy) void(^returnStateInformation)(NSString *stateInformation);
+ (instancetype)shareInstance;
- (BOOL)connectToHost:(NSString *)ip port:(NSNumber *)port;
- (void)disConnect;
- (void)sendMessage:(NSString *)message;

@end
