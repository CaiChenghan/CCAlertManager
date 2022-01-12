//
//  CCAlertManager.m
//  CCAlertManager
//
//  Created by 蔡成汉 on 2019/11/28.
//  Copyright © 2019 蔡成汉. All rights reserved.
//

#import "CCAlertManager.h"
#import <objc/message.h>

#import <objc/message.h>

@interface CCAlertModel : NSObject

@property (nonatomic, strong) UIViewController *controller;
@property (nonatomic, copy) NSArray<Class> *whiteControllers;
@property (nonatomic, copy) NSArray<Class> *blackControllers;
@property (nonatomic, assign) BOOL animated;
@property (nonatomic, assign) BOOL forceAlert;

@end


@interface UIViewController (CCAlert)

@property (nonatomic, copy) void(^cc_controllerDismissCallBack)(void);
@property (nonatomic, assign) BOOL cc_forceClose;

@end


@interface CCAlertManager ()

@property (nonatomic, strong) NSMutableArray<CCAlertModel *> *defaultArray;
@property (nonatomic, strong) NSMutableArray<CCAlertModel *> *forceAlertArray;
@property (nonatomic, assign) BOOL isAlerting;
@property (nonatomic, assign) BOOL isCloseAlerting;
@property (nonatomic, strong) dispatch_queue_t alertQueue;
@property (nonatomic, strong) CCAlertModel *currentAlertModel;

@end

@implementation CCAlertManager

+ (CCAlertManager *)sharedManager {
    static CCAlertManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

/// 添加弹窗：任意位置展示
+ (void)addAlertController:(UIViewController *)controller {
    [self addAlertController:controller animated:YES];
}

+ (void)addAlertController:(UIViewController *)controller animated:(BOOL)animated {
    [[CCAlertManager sharedManager] addAlertController:controller animated:animated];
}

- (void)addAlertController:(UIViewController *)controller animated:(BOOL)animated {
    CCAlertModel *model = [[CCAlertModel alloc] init];
    model.controller = controller;
    SEL whiteControllersSelector = NSSelectorFromString(@"cc_alertWhiteControllers");
    if ([model.controller respondsToSelector:whiteControllersSelector]) {
        model.whiteControllers = ((NSArray * (*)(id, SEL))objc_msgSend)(controller, whiteControllersSelector);
    }
    SEL blackControllersSelector = NSSelectorFromString(@"cc_alertBlackControllers");
    if ([model.controller respondsToSelector:blackControllersSelector]) {
        model.blackControllers = ((NSArray * (*)(id, SEL))objc_msgSend)(controller, blackControllersSelector);
    }
    SEL forceAlertSelector = NSSelectorFromString(@"cc_alertControllerForce");
    if ([model.controller respondsToSelector:forceAlertSelector]) {
        model.forceAlert = ((BOOL (*)(id, SEL))objc_msgSend)(controller, forceAlertSelector);
    }
    model.animated = animated;
    [(model.forceAlert ? self.forceAlertArray : self.defaultArray) addObject:model];
    [self tryAlert:0];
}

- (void)tryAlert:(NSTimeInterval)delay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.currentAlertModel.forceAlert && self.isAlerting) return;
        if (self.forceAlertArray.count == 0 && self.defaultArray.count == 0) return;
        __weak typeof(self) weakSelf = self;
        [self getAlert:self.forceAlertArray complete:^(CCAlertModel *model) {
            if (model) {
                [weakSelf closeDefaultAlert:weakSelf.currentAlertModel complete:^{
                    weakSelf.isAlerting = YES;
                    weakSelf.currentAlertModel = model;
                    [weakSelf showAlert:model];
                }];
            } else {
                if (self.isAlerting) return;
                if (self.defaultArray.count == 0) return;
                [weakSelf getAlert:weakSelf.defaultArray complete:^(CCAlertModel *model) {
                    weakSelf.isAlerting = YES;
                    weakSelf.currentAlertModel = model;
                    [weakSelf showAlert:model];
                }];
            }
        }];
    });
}

- (void)getAlert:(NSArray<CCAlertModel *> *)alertArray complete:(void(^)(CCAlertModel *model))complete {
    UIViewController *topController = [self getTopController];
    if (topController.view.superview == nil || topController.view.window == nil) return;
    dispatch_async(self.alertQueue, ^{
        CCAlertModel *alertModel = nil;
        for (NSInteger i = 0; i < alertArray.count; i++) {
            @autoreleasepool {
                CCAlertModel *model = alertArray[i];
                if (model.whiteControllers.count > 0) {
                    /// 设置有白名单
                    if ([model.whiteControllers containsObject:topController.class]) {
                        alertModel = model;
                        break;
                    }
                } else if (model.blackControllers.count > 0) {
                    /// 设置有黑名单
                    if (![model.blackControllers containsObject:topController.class]) {
                        alertModel = model;
                        break;
                    }
                } else {
                    /// 任意界面弹出
                    alertModel = model;
                    break;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (complete) {
                complete(alertModel);
            }
        });
    });
}

- (void)showAlert:(CCAlertModel *)model {
    if (model == nil) return;
    model.controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    model.controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    UIViewController *rootViewController = [self getRootController];
    if (rootViewController == nil) return;
    [rootViewController presentViewController:model.controller animated:model.animated completion:^{
        SEL selector = NSSelectorFromString(@"cc_alertControllerDidAlert");
        if ([model.controller respondsToSelector:selector]) {
            ((void (*)(id, SEL))objc_msgSend)(model.controller, selector);
        }
    }];
    __weak typeof(self) weakSelf = self;
    model.controller.cc_controllerDismissCallBack = ^{
        [(weakSelf.currentAlertModel.forceAlert ? weakSelf.forceAlertArray : weakSelf.defaultArray) removeObject:weakSelf.currentAlertModel];
        weakSelf.currentAlertModel = nil;
        weakSelf.isAlerting = NO;
        [weakSelf tryAlert:0.25];
    };
}

- (void)closeDefaultAlert:(CCAlertModel *)model complete:(void(^)(void))complete {
    if (self.isCloseAlerting || model.forceAlert) return;
    if (model) {
        self.isCloseAlerting = YES;
        model.controller.cc_forceClose = YES;
        __weak typeof(self) weakSelf = self;
        [model.controller dismissViewControllerAnimated:model.animated completion:^{
            weakSelf.isCloseAlerting = NO;
            model.controller.cc_forceClose = NO;
            if (complete) complete();
        }];
    } else {
        if (complete) complete();
    }
}

- (dispatch_queue_t)alertQueue {
    if (_alertQueue == nil) {
        _alertQueue = dispatch_queue_create("cc.alertManager.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _alertQueue;
}

- (NSMutableArray<CCAlertModel *> *)defaultArray {
    if (_defaultArray == nil) {
        _defaultArray = [NSMutableArray array];
    }
    return _defaultArray;
}

- (NSMutableArray<CCAlertModel *> *)forceAlertArray {
    if (_forceAlertArray == nil) {
        _forceAlertArray = [NSMutableArray array];
    }
    return _forceAlertArray;
}

- (UIViewController *)getRootController {
    UIViewController *controller = nil;
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        if (window.isKeyWindow) {
            controller = window.rootViewController;
            break;
        }
    }
    return controller;
}

- (UIViewController *)getTopController {
    return [self _getTopController:[self getRootController]];
}

- (UIViewController *)_getTopController:(UIViewController *)rootController {
    if ([rootController isKindOfClass:[UITabBarController class]]) {
        return [self _getTopController:((UITabBarController *)rootController).selectedViewController];
    } else if ([rootController isKindOfClass:[UINavigationController class]]) {
        return [self _getTopController:((UINavigationController *)rootController).visibleViewController];
    } else if (rootController.presentedViewController) {
        return [self _getTopController:rootController.presentedViewController];
    } else {
        return rootController;
    }
}

@end


@implementation CCAlertModel

@end


@implementation UIViewController (CCAlert)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self cc_swizzledViewDidAppear];
        [self cc_swizzledDismissViewControllerAnimated];
    });
}

+ (void)cc_swizzledViewDidAppear {
    SEL originSelector = @selector(viewDidAppear:);
    SEL swizzledSelector = @selector(cc_viewDidAppear:);
    Method originMethod = class_getInstanceMethod([self class], originSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    BOOL success = class_addMethod([self class], originSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod([self class], swizzledSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, swizzledMethod);
    }
}

+ (void)cc_swizzledDismissViewControllerAnimated {
    SEL originSelector = @selector(dismissViewControllerAnimated:completion:);
    SEL swizzledSelector = @selector(cc_dismissViewControllerAnimated:completion:);
    Method originMethod = class_getInstanceMethod([self class], originSelector);
    Method swizzledMethod = class_getInstanceMethod([self class], swizzledSelector);
    BOOL success = class_addMethod([self class], originSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod([self class], swizzledSelector, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, swizzledMethod);
    }
}

- (void)cc_viewDidAppear:(BOOL)animated {
    [self cc_viewDidAppear:animated];
    SEL selector = NSSelectorFromString(@"tryAlert:");
    if ([[CCAlertManager sharedManager] respondsToSelector:selector]) {
           ((void (*)(id, SEL, NSTimeInterval))objc_msgSend)([CCAlertManager sharedManager], selector, 0.25);
    }
}

- (void)cc_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [self cc_dismissViewControllerAnimated:flag completion:^{
        if (self.cc_controllerDismissCallBack && self.cc_forceClose == NO) {
            self.cc_controllerDismissCallBack();
        }
        if (completion) {
            completion();
        }
    }];
}

- (void)setCc_controllerDismissCallBack:(void (^)(void))cc_controllerDismissCallBack {
    objc_setAssociatedObject(self, @selector(cc_controllerDismissCallBack), cc_controllerDismissCallBack, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(void))cc_controllerDismissCallBack {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setCc_forceClose:(BOOL)cc_forceClose {
    objc_setAssociatedObject(self, @selector(cc_forceClose), @(cc_forceClose), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cc_forceClose {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end
