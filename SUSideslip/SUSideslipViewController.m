//
//  SUSideslipViewController.m
//  侧滑菜单（抽屉效果） v1.0
//
//  Created by 苏俊海 on 15/9/5.
//  Copyright (c) 2015年 sujunhai. All rights reserved.
//

#import "SUSideslipViewController.h"

// 屏幕宽高
#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

// 侧滑x轴的最大比例
#define kAnimationSlideScaleX _animationSlideScale
// 侧滑y轴的最大比例
#define kAnimationSlideScaleY ((1 - _animationZoomScale) / 2)

// 缩放的最小比例
#define kAnimationZoomScale _animationZoomScale

// 动画中滑动的方向
typedef NS_ENUM(NSInteger, SUSideslipAnimationSlideDirection) {
    SUSideslipAnimationSlideNone,
    SUSideslipAnimationSlideRight,
    SUSideslipAnimationSlideLeft
};

@interface SUSideslipViewController ()
{
    NSMutableArray *_speedArray;
    UITapGestureRecognizer *_tapGestureRecognizer;
    UIView *_coverView;
    BOOL _animationComplete;
    CGRect _mainViewFrame;
    SUSideslipAnimationSlideDirection _animationSlideDirection;
}
@end

@implementation SUSideslipViewController

// 便利构造器
+ (instancetype)sideslipViewControllerWithLeftViewController:(UIViewController *)leftViewController mainViewController:(UIViewController *)mainViewController {
    SUSideslipViewController *sideslipViewController = [[SUSideslipViewController shareInstance] initWithLeftViewController:leftViewController mainViewController:mainViewController];
    return sideslipViewController;
}

// 初始化
- (instancetype)initWithLeftViewController:(UIViewController *)leftViewController mainViewController:(UIViewController *)mainViewController {
    self = [super init];
    if (self) {
        // 属性赋值
        _leftViewController = leftViewController;
        _mainViewController = mainViewController;
        
        // 默认设置
        _animationType = SUSideslipAnimationTypeZoom;
        _animationSlideScale = 0.78;
        _animationZoomScale = 0.78;
        _shadowEnabled = NO;
        _animationSlideDirection = SUSideslipAnimationSlideNone;
        
        // 初始化数组
        _speedArray = [NSMutableArray array];
        
        // 通知的标志
        SUSideslipMainViewDidScrollNotification = @"SUSideslipMainViewDidScrollNotification";
        SUSideslipMainViewHadGoneBackNotification = @"SUSideslipMainViewHadGoneBackNotification";
    }
    return self;
}

// 单例
+ (instancetype)shareInstance {
    static SUSideslipViewController *suSideslipViewController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        suSideslipViewController = [[SUSideslipViewController alloc] init];
    });
    return suSideslipViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 没有这句，就不能控制子控制器
    [self addChildViewController:_leftViewController];
    [self addChildViewController:_mainViewController];
    // 侧滑菜单的原理就是对view的操作
    [self.view addSubview:_leftViewController.view];
    [self.view addSubview:_mainViewController.view];
    // 添加手势
    [self addGestureRecognizer];
    // 添加一个鉴听
    [self addKVO];
}

// 鉴听
- (void)addKVO {
    [_mainViewController.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}
// 鉴听的回调方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    CGRect rect = _mainViewController.view.frame;
    // 去掉进入动画瞬间的值
    if (rect.origin.x != kAnimationSlideScaleX * kScreenWidth && rect.origin.x != 0) {
        [self postNotificationWithMainViewFrameValue:[NSValue valueWithCGRect:rect]];
    }
}

// 添加手势
- (void)addGestureRecognizer {
    // 拖动手势
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerMethod:)];
    [_mainViewController.view addGestureRecognizer:panGestureRecognizer];
    // 点击手势
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerMethod)];
    // 一开始无效
    _tapGestureRecognizer.enabled = NO;
    [_mainViewController.view addGestureRecognizer:_tapGestureRecognizer];
}

// 拖动手势方法
- (void)panGestureRecognizerMethod:(UIPanGestureRecognizer *)panGestureRecognizer {
    // 1.手指按下拖动到手指放开的距离
    CGPoint point = [panGestureRecognizer translationInView:self.view];
    // 1和2配合使用，可以得到瞬间拖动的距离，可以用这个瞬间距离的大小来表示速度的快慢（发现垂直零敏度比水平的小很多）
    CGFloat speed = point.x;
//    NSLog(@"%f", speed);
    // 2.每次调用“拖动手势方法”就把距离清零（每次清零的时间固定）
    [panGestureRecognizer setTranslation:CGPointZero inView:self.view];
    
    // 记录speed
    [_speedArray addObject:[NSNumber numberWithFloat:speed]];
    
    // 取消或放开手指或失效的时候
    if (panGestureRecognizer.state == UIGestureRecognizerStateCancelled || panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        // 自定义speed的绝对值超过20为快拖，否则为慢拖
        // 因为放开手指的瞬间speed为0，所以要判断数组里的最后5个元素是否包含超过20的数
        if ([self isContainSharpSpeed] == 1) {
            // 向右快拖
            [self rightSharpPan];
        } else if ([self isContainSharpSpeed] == 2) {
            // 向左快拖
            [self leftSharpPan];
        } else {
            // 超过可拖动范围的一半
            if (_mainViewController.view.frame.origin.x > kAnimationSlideScaleX * kScreenWidth / 2) {
                [self rightSharpPan];
            } else
                [self leftSharpPan];
        }
        // 数组清零
        [_speedArray removeAllObjects];
    } else
        // 慢拖
        [self slowPan:speed panGestureRecognizer:panGestureRecognizer];
    
    // 为主控制器添加阴影
    [self setShadowForMainView];
}
// 为主控制器添加阴影
- (void)setShadowForMainView {
    CALayer *layer = _mainViewController.view.layer;
    // 阴影颜色
    layer.shadowColor = [UIColor blackColor].CGColor;
    // 偏移距离
    layer.shadowOffset = CGSizeMake(0, 0);
    
    if (_shadowEnabled) {
        // 不透明度
        layer.shadowOpacity = 0.5;
    } else
        layer.shadowOpacity = 0;
    
    // 阴影半径
    layer.shadowRadius = 10;
    
    CGRect bounds = _mainViewController.view.bounds;
    if (_animationSlideDirection == SUSideslipAnimationSlideRight) {
        bounds.size = CGSizeMake(kAnimationZoomScale * kScreenWidth, kAnimationZoomScale * kScreenHeight);
    } else if (_animationSlideDirection == SUSideslipAnimationSlideLeft) {
        bounds.size = CGSizeMake(kScreenWidth, kScreenHeight);
    }
    
    // 参考：http://blog.csdn.net/meegomeego/article/details/22728465
    // 提前告诉CoreAnimation要渲染的View的形状Shape,就会减少离屏渲染计算
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:bounds];
    layer.shadowPath = shadowPath.CGPath;
}
// 点击手势方法
- (void)tapGestureRecognizerMethod {
    [self leftSharpPan];
}

// 判断数组里是否包含大于20的数
- (NSInteger)isContainSharpSpeed {
    // 只遍历最后5个元素
    NSInteger i = 0;
    if (_speedArray.count > 5) {
        i = _speedArray.count - 5;
    }
    for (; i < _speedArray.count; i++) {
        CGFloat speed = [_speedArray[i] floatValue];
        if (speed > 20) {
            return 1;
        }
        if (speed < -20) {
            return 2;
        }
    }
    return 0;
}

// 向右快拖方法
- (void)rightSharpPan {
    CGRect rect;
    if (_animationType == SUSideslipAnimationTypeZoom) {
        rect = CGRectMake(kAnimationSlideScaleX * kScreenWidth, kAnimationSlideScaleY * kScreenHeight, kAnimationZoomScale * kScreenWidth, kAnimationZoomScale * kScreenHeight);
    } else
        rect = CGRectMake(kAnimationSlideScaleX * kScreenWidth, 0, kScreenWidth, kScreenHeight);
    _animationComplete = NO;
    _animationSlideDirection = SUSideslipAnimationSlideRight;
    [self setShadowForMainView];
    
    [self animationDoing];
    
    [UIView animateWithDuration:0.2 animations:^{
        _mainViewController.view.frame = rect;
    } completion:^(BOOL finished) {
        _tapGestureRecognizer.enabled = YES;
        [self addCover];
        
        // 在最后修正下覆盖层的frame
        _coverView.frame = _mainViewFrame;
        CGRect rect = _coverView.frame;
        rect.origin = CGPointMake(0, 0);
        _coverView.frame = rect;
        
        _animationComplete = YES;
        _animationSlideDirection = SUSideslipAnimationSlideNone;
    }];
}
// 向左快拖方法
- (void)leftSharpPan {
    CGRect rect = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    _animationComplete = NO;
    _animationSlideDirection = SUSideslipAnimationSlideLeft;
    
    [self animationDoing];
    
    [UIView animateWithDuration:0.2 animations:^{
        _mainViewController.view.frame = rect;
    } completion:^(BOOL finished) {
        _tapGestureRecognizer.enabled = NO;
        if (_coverView) {
            [self removeCover];
        }
        _animationComplete = YES;
        _animationSlideDirection = SUSideslipAnimationSlideNone;
        [self setShadowForMainView];
        
        [self postNotificationHadGoneBackWithMainViewFrameValue:[NSValue valueWithCGRect:rect]];
    }];
}
// 发送主控制器回到原点时的通知
- (void)postNotificationHadGoneBackWithMainViewFrameValue:(NSValue *)mainViewFrameValue {
    [[NSNotificationCenter defaultCenter] postNotificationName:SUSideslipMainViewHadGoneBackNotification object:mainViewFrameValue];
}
// 动画中执行
- (void)animationDoing {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (!_animationComplete) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                // 动画中_mainViewController.view.frame只会得到最终结果，而[_mainViewController.view.layer.presentationLayer frame]可以得到实时结果
                _mainViewFrame = [_mainViewController.view.layer.presentationLayer frame];
                if (_mainViewFrame.origin.x != 0) {
                    [self postNotificationWithMainViewFrameValue:[NSValue valueWithCGRect:_mainViewFrame]];
                }
            });
        }
    });
}
// 发送主控制器移动中的通知
- (void)postNotificationWithMainViewFrameValue:(NSValue *)mainViewFrameValue {
    [[NSNotificationCenter defaultCenter] postNotificationName:SUSideslipMainViewDidScrollNotification object:mainViewFrameValue];
}

// 慢拖方法
- (void)slowPan:(CGFloat)speed panGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGRect rect = _mainViewController.view.frame;
    // 瞬间位置
    CGFloat instantX = rect.origin.x += speed;
    
    // 比例
    CGFloat scaleX = instantX / (kAnimationSlideScaleX * kScreenWidth);
    
    // 超出两端时不改变frame
    if (scaleX < 0) {
        _tapGestureRecognizer.enabled = NO;
        if (_coverView) {
            [self removeCover];
        }
        return;
    } else if (scaleX > 1) {
        _tapGestureRecognizer.enabled = YES;
        [self addCover];
        return;
    }
    
    CGFloat instantY = scaleX * kAnimationSlideScaleY * kScreenHeight;
    CGFloat instantHeight = kScreenHeight - 2 * instantY;
    CGFloat instantWidth = instantHeight * kScreenWidth / kScreenHeight;
    
    if (_animationType == SUSideslipAnimationTypeZoom) {
        rect = CGRectMake(instantX, instantY, instantWidth, instantHeight);
    } else
        rect = CGRectMake(instantX, 0, kScreenWidth, kScreenHeight);
    _mainViewController.view.frame = rect;
}

// 添加覆盖层
- (void)addCover {
    if (_coverView) {
        return;
    }
    _coverView = [[UIView alloc] initWithFrame:_mainViewController.view.frame];
    CGRect rect = _coverView.frame;
    rect.origin = CGPointMake(0, 0);
    _coverView.frame = rect;
    [_mainViewController.view addSubview:_coverView];
}
// 移除覆盖层
- (void)removeCover {
    [_coverView removeFromSuperview];
    _coverView = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
