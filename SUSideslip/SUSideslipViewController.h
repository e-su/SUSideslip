//
//  SUSideslipViewController.h
//  侧滑菜单（抽屉效果） v1.2
//
//  Created by 苏俊海 on 15/9/5.
//  Copyright (c) 2015年 sujunhai. All rights reserved.
//

/*
 简介：
 只要给我传入两个控制器，我便给你一个抽屉
 提供的效果设置有：侧滑样式，可滑动距离，缩放比例，添加阴影
 
 使用：
 1.把SUSideslip文件夹拖到项目中
 2.在AppDelegate.m中导入SUSideslipViewController.h
 3.用便利构造器：sideslipViewControllerWithLeftViewController: mainViewController:初始化实例
 4.设置self.window.rootViewController为SUSideslipViewController的实例
 */

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SUSideslipAnimationType) {
    /**
     侧滑时缩放效果
     */
    SUSideslipAnimationTypeZoom,
    /**
     侧滑时扁平效果
     */
    SUSideslipAnimationTypePlain
};

@interface SUSideslipViewController : UIViewController

@property (nonatomic, strong) UIViewController *leftViewController;
@property (nonatomic, strong) UIViewController *mainViewController;

/**
 侧滑时的动画效果，缩放或扁平，默认缩放
 */
@property (nonatomic, assign) SUSideslipAnimationType animationType;

/**
 可滑动的最大比例，默认0.78
 */
@property (nonatomic, assign) CGFloat animationSlideScale;

/**
 缩放的最小比例，默认0.78
 */
@property (nonatomic, assign) CGFloat animationZoomScale;

/**
 添加阴影，默认NO
 */
@property (nonatomic, assign) BOOL shadowEnabled;

/**
 便利构造器：传入左控制器和主控制器来初始化侧滑菜单，主控制器可以是UINavigationController或UITabBarController
 */
+ (instancetype)sideslipViewControllerWithLeftViewController:(UIViewController *)leftViewController mainViewController:(UIViewController *)mainViewController;

/**
 当想在其它类使用SUSideslipViewController的实例时，可用这个方法获得
 */
+ (instancetype)shareInstance;

/**
 使主控制器滑到屏幕最右侧，比如当你点击导航控制器左侧按钮，想实现此效果时可以调用
 */
- (void)rightSharpPan;

@end

/**
 主控制器正在滑动
 作为接收通知中name的参数。当你想进行一些联动，比如想要一些效果随着主控制器的滑动而改变，就可以使用此参数
 使用：
 1.导入SUSideslipViewController.h（不导入就把SUSideslipMainViewDidScrollNotification改成@"SUSideslipMainViewDidScrollNotification"）
 2.把self注册成为观察者
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(methodName:) name:SUSideslipMainViewDidScrollNotification object:nil];
 3.在方法中获取主控制器视图在滑动中的frame
 - (void)methodName:(NSNotification *)notification {
 CGRect mainViewFrame = [notification.object CGRectValue];
 }
 */
NSString *SUSideslipMainViewDidScrollNotification;
/**
 主控制器回到了原点
 */
NSString *SUSideslipMainViewHadGoneBackNotification;
