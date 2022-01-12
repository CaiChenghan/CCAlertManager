//
//  CCViewController.m
//  CCAlertManager
//
//  Created by 1178752402@qq.com on 11/29/2019.
//  Copyright (c) 2019 1178752402@qq.com. All rights reserved.
//

#import "CCViewController.h"
#import <CCAlertManager/CCAlertManager.h>
#import "AlertViewController.h"

@interface CCViewController ()

@end

@implementation CCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(buttonIsTouch) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:300];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0.0 constant:400];
    [button addConstraints:@[width,height]];
    [self.view addConstraints:@[centerX,centerY]];
}

- (void)buttonIsTouch {
    [self addAlert];
}

- (void)addAlert {
    AlertViewController *controller = [[AlertViewController alloc]init];
    [CCAlertManager addAlertController:controller];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
