//
//  ViewController.m
//  Mac服务器
//
//  Created by Locke on 2017/6/14.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import "ViewController.h"
#import "GCDSocketManager.h"

@interface ViewController ()
@property (nonatomic, strong) GCDSocketManager *manager;

//操作系统上端口号1024以下是系统保留的，从1024-65535是用户使用的
@property (weak) IBOutlet NSTextField *portNumber;
@property (weak) IBOutlet NSTextField *sMessage;
@property (unsafe_unretained) IBOutlet NSTextView *aMessage;


@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [GCDSocketManager shareInstance];
    __weak typeof(self) weak_self = self;
    [self.manager setReturnStateInformation:^(NSString *stateInformation){
        __strong typeof(weak_self) self = weak_self;
        self.aMessage.string = stateInformation;
    }];
}

//监听端口号
- (IBAction)listenToSocket:(id)sender {
    [self.manager acceptOnPort:@(self.portNumber.intValue)];
}
- (IBAction)disConnect:(id)sender {
    [self.manager disConnect];
}

- (IBAction)sendMessage:(id)sender {
    [self.manager sendMessage:self.sMessage.stringValue];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


@end
