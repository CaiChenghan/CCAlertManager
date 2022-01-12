//
//  CCAlertManager.h
//  CCAlertManager
//
//  Created by 蔡成汉 on 2019/11/28.
//  Copyright © 2019 蔡成汉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCAlertManager : NSObject

/// 添加弹窗：任意位置展示
+ (void)addAlertController:(UIViewController *)controller;
+ (void)addAlertController:(UIViewController *)controller animated:(BOOL)animated;

@end

@protocol CCAlertManagerProtocol <NSObject>

@optional

/// 弹窗白名单：只在白名单内展示
- (NSArray *)cc_alertWhiteControllers;

/// 弹窗黑名单：黑名单内不展示
- (NSArray *)cc_alertBlackControllers;

/// 弹窗弹出
- (void)cc_alertControllerDidAlert;

/// 强制弹窗
- (BOOL)cc_alertControllerForce;

@end

NS_ASSUME_NONNULL_END
