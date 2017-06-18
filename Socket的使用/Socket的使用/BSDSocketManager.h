//
//  BSDSocketManager.h
//  Socket的使用
//
//  Created by Locke on 2017/6/14.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BSDSocketManager : NSObject
@property (nonatomic, copy) void(^returnStateInformation)(NSString *stateInformation);
+ (instancetype)shareInstance;
- (void)connectToHost:(NSString *)ip port:(NSNumber *)port;
- (void)disConnect;
- (void)sendMessage:(NSString *)message;


@end
