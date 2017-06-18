//
//  AppDelegate.h
//  Socket的使用
//
//  Created by Locke on 2017/6/14.
//  Copyright © 2017年 lainkai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

