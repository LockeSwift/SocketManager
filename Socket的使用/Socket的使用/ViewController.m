//
//  ViewController.m
//  Socket的使用
//
//  Created by Locke on 2017/6/14.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import "ViewController.h"
#import "BSDSocketManager.h"
#import "GCDSocketManager.h"

@interface ViewController ()

@property (nonatomic, strong) NSString *ip;
//@property (nonatomic, strong) BSDSocketManager *manager;
@property (nonatomic, strong) GCDSocketManager *manager;
@property (weak, nonatomic) IBOutlet UITextField *port;
@property (weak, nonatomic) IBOutlet UITextField *sMessage;
@property (weak, nonatomic) IBOutlet UITextView *aMessage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ip = @"127.0.0.1";
//    self.manager =  [BSDSocketManager shareInstance];
    self.manager = [GCDSocketManager shareInstance];
    __weak typeof(self) weak_self = self;
    [self.manager setReturnStateInformation:^(NSString *stateInformation){
        __strong typeof(weak_self) self = weak_self;
        self.aMessage.text = stateInformation;
    }];
}
- (IBAction)connect:(id)sender {
    //Socket链接
    [self.manager connectToHost:self.ip port:[NSNumber numberWithInt:[self.port.text intValue]]];
}
- (IBAction)send:(id)sender {
    //发送消息
    [self.manager sendMessage:self.sMessage.text];
}
- (IBAction)close:(id)sender {
    //断开连接
    [self.manager disConnect];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
