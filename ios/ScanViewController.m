//
//  ScanViewController.m
//  QuickpeWallet
//
//  Created by 宋航 on 2022/3/14.
//

#import "ScanViewController.h"
#import "SanYueDismissAnimation.h"
#import "SanYuePanInteractiveTransition.h"
#import "SanYueModalController.h"
#import "SanYueAlertItem.h"
#import <AVFoundation/AVFoundation.h>
#import "UIColor+SanYueExtension.h"

@interface ScanViewController ()<UIViewControllerTransitioningDelegate,UIGestureRecognizerDelegate,AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic,strong)SanYuePanInteractiveTransition *panInteractiveTransition;
@property (nonatomic,strong)SanYueDismissAnimation *dismissAnimation;
@property (nonatomic,strong)AVCaptureDevice *device; //AVCaptureDeviceInput 代表输入设备，他使用AVCaptureDevice 来初始化
@property (nonatomic,strong)AVCaptureDeviceInput *input;//当启动摄像头开始捕获输入
@property (nonatomic,strong)AVCaptureMetadataOutput *output;
@property (nonatomic,strong)AVCaptureSession *session;//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;//图像预览层，实时显示捕获的图像
@property(nonatomic,assign)BOOL hasCheckAuth;
@property(nonatomic,weak)UIView *videoView;
@property(nonatomic,weak)UIView *lineView;
@property (nonatomic, strong) UIImpactFeedbackGenerator *impactLight;
@end

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.transitioningDelegate = self;
    [self.panInteractiveTransition panToDismiss:self];
    [self setView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
- (BOOL)prefersStatusBarHidden{
    return NO;
}
-(void)applicationDidBecomeActive{
    if(self.lineView){
        [self lineStop];
        [self lineStart];
    }
}
-(void)viewDidAppear:(BOOL)animated{
    if(!_hasCheckAuth){
        [self checkAuthStatus];
    }
    [super viewDidAppear:animated];
}
-(void)setView{
    UIColor *mainColor = [UIColor colorWithHexString:self.mainColor];
    // 相机
    UIView *videoView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:videoView];
    _videoView = videoView;
    int SANScreenH =  [UIScreen mainScreen].bounds.size.height;
    int SANScreenW = [UIScreen mainScreen].bounds.size.width;
    // 扫码边框
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SANScreenW, (SANScreenH - 200) * 0.5 )];
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0,CGRectGetMaxY(topView.frame) + 200, SANScreenW, (SANScreenH - 200) * 0.5 )];
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(topView.frame), (SANScreenW - 200) * 0.5, 200)];
    UIView *rightView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame) + 200, CGRectGetMaxY(topView.frame), (SANScreenW - 200) * 0.5, 200)];
    topView.backgroundColor = UIColor.blackColor;
    bottomView.backgroundColor = UIColor.blackColor;
    rightView.backgroundColor = UIColor.blackColor;
    leftView.backgroundColor = UIColor.blackColor;
    bottomView.alpha = 0.6;
    topView.alpha = 0.6;
    rightView.alpha = 0.6;
    leftView.alpha = 0.6;
    [self.view addSubview:topView];
    [self.view addSubview:bottomView];
    [self.view addSubview:leftView];
    [self.view addSubview:rightView];
    UIView *topLeftView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame), leftView.frame.origin.y, 40, 4)];
    UIView *topRightView = [[UIView alloc] initWithFrame:CGRectMake(rightView.frame.origin.x - 40, leftView.frame.origin.y, 40, 4)];
    UIView *bottomLeftView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame), bottomView.frame.origin.y - 4, 40, 4)];
    UIView *bottomRightView = [[UIView alloc] initWithFrame:CGRectMake(rightView.frame.origin.x - 40, bottomView.frame.origin.y - 4, 40, 4)];
    UIView *leftTopView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame), leftView.frame.origin.y, 4, 40)];
    UIView *rightTopView = [[UIView alloc] initWithFrame:CGRectMake(rightView.frame.origin.x - 4, leftView.frame.origin.y, 4, 40)];
    UIView *leftBottomView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(leftView.frame), bottomView.frame.origin.y - 40, 4, 40)];
    UIView *rightBottomView = [[UIView alloc] initWithFrame:CGRectMake(rightView.frame.origin.x - 4, bottomView.frame.origin.y - 40, 4, 40)];
    topLeftView.backgroundColor = mainColor;
    topRightView.backgroundColor = mainColor;
    bottomLeftView.backgroundColor = mainColor;
    bottomRightView.backgroundColor = mainColor;
    leftTopView.backgroundColor = mainColor;
    rightTopView.backgroundColor = mainColor;
    leftBottomView.backgroundColor = mainColor;
    rightBottomView.backgroundColor = mainColor;
    [self.view addSubview:topLeftView];
    [self.view addSubview:topRightView];
    [self.view addSubview:bottomLeftView];
    [self.view addSubview:bottomRightView];
    [self.view addSubview:leftTopView];
    [self.view addSubview:rightTopView];
    [self.view addSubview:leftBottomView];
    [self.view addSubview:rightBottomView];
    // 扫码动画
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake((SANScreenW - 170) * 0.5, leftView.frame.origin.y + 4, 170, 4)];
    line.alpha = 0.8;
    line.backgroundColor = mainColor;
    _lineView = line;
    [self.view addSubview:line];
    // close btn
    int SANStatusH = SANScreenH >= 812 ? 44 : 20;
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20 + SANStatusH, 36, 36)];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 20, 20)];
    NSBundle *resourceBundle = [self getBundle:self.classForCoder];
    UIImage *img = [UIImage imageNamed:@"close" inBundle:resourceBundle compatibleWithTraitCollection:nil];
    [imageView setImage:img];
    btn.backgroundColor = UIColor.whiteColor;
    btn.layer.cornerRadius = 18;
    [btn addSubview:imageView];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(backBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    
}
-(NSBundle *)getBundle:(Class)aClass{
    NSBundle *bundle = [NSBundle bundleForClass:self.classForCoder];
    NSURL *bundleURL = [[bundle resourceURL] URLByAppendingPathComponent:@"LightWebCore.bundle"];
    NSBundle *resourceBundle = [NSBundle bundleWithURL:bundleURL];
    return resourceBundle;
}
-(void)backBtnEvent{
    if(self.delegate) {
        [self.delegate getError:@"User cancelled scan"];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)checkAuthStatus{
    _hasCheckAuth = YES;
    // 判断权限
    NSString *mediaType = AVMediaTypeVideo;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];//读取设备授权状态
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        SanYueAlertItem *item = [[SanYueAlertItem alloc] initWithDict:@{
            @"senseMode":@1,
            @"title":self.errorTitle,
            @"content":self.errorContent,
            @"confirmText":self.confirmText,
            @"cancelText":self.cancelText,
            @"showCancel":@1,
        }];
        
        SanYueModalController *vc = [[SanYueModalController alloc] initWithItem:item andHandler:^(int index) {
            if(index != 0){
                [self.lineView.layer removeAllAnimations];
                NSURL *url = [NSURL URLWithString:@"App-Prefs:root=Privacy&path=CAMERA"];
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            }
            [self backBtnEvent];
            [self.preVc dismissViewControllerAnimated:YES completion:nil];
        }];
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }
    else{
        // 相机可以用，设置 UI
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
        
        self.output = [[AVCaptureMetadataOutput alloc]init];
        [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        self.session = [[AVCaptureSession alloc]init];
            
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
             self.session.sessionPreset = AVCaptureSessionPreset1280x720;
        }
        
        if ([self.session canAddInput:self.input]) {
            [self.session addInput:self.input];
        }
        
        if ([self.session canAddOutput:self.output]) {
            [self.session addOutput:self.output];
            self.output.metadataObjectTypes= @[AVMetadataObjectTypeQRCode];
        }
        self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
         
        self.previewLayer.frame = self.view.bounds;
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [_videoView.layer addSublayer:self.previewLayer];
        [self.session startRunning];
        [self lineStart];
    }
}
-(void)lineStart{
    int SANScreenH =  [UIScreen mainScreen].bounds.size.height;
    int SANScreenW = [UIScreen mainScreen].bounds.size.width;
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        self.lineView.frame = CGRectMake((SANScreenW - 170) * 0.5,(SANScreenH - 200) * 0.5 + 200 - 8, 170, 4);
    } completion:^(BOOL finished) {
        
    }];
}
-(void)lineStop{
    int SANScreenH =  [UIScreen mainScreen].bounds.size.height;
    int SANScreenW = [UIScreen mainScreen].bounds.size.width;
    self.lineView.frame = CGRectMake((SANScreenW - 170) * 0.5,(SANScreenH - 200) * 0.5 + 4, 170, 4);
}
#pragma mark -- 懒加载
- (SanYuePanInteractiveTransition *)panInteractiveTransition{
    if(!_panInteractiveTransition) _panInteractiveTransition = [[SanYuePanInteractiveTransition alloc] init];
    return _panInteractiveTransition;
}
- (SanYueDismissAnimation *)dismissAnimation{
    if(!_dismissAnimation) _dismissAnimation = [[SanYueDismissAnimation alloc] init];
    return _dismissAnimation;
}
-(UIImpactFeedbackGenerator *)impactLight API_AVAILABLE(ios(10.0)){
    if (!_impactLight) {
        UIImpactFeedbackGenerator *impactLight = [[UIImpactFeedbackGenerator alloc]initWithStyle:UIImpactFeedbackStyleMedium];
        _impactLight = impactLight;
        [_impactLight prepare];
    }
    return _impactLight;
}
#pragma mark -- 进入退出的过渡动画
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context){
        UIView *view = [context viewForKey:UITransitionContextFromViewKey];
        view.alpha = 0.5;
        view.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context){
        UIView *view = [context viewForKey:UITransitionContextToViewKey];
        view.alpha = 1;
        view.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {}];
}

#pragma mark - UIViewControllerTransitioningDelegate
-(id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.dismissAnimation;
}
-(id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    return self.panInteractiveTransition.isInteractive ? self.panInteractiveTransition : nil;
}
- (void)dealloc{
    _panInteractiveTransition = nil;
    _dismissAnimation = nil;
    _session = nil;
    _device = nil;
    _input = nil;
    _output = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

#pragma mark -- AVCaptureMetadataOutputObjectsDelegate
-(void)getResult:(NSString *)res{
    [self.impactLight impactOccurred];
    [_session stopRunning];
    [_lineView.layer removeAllAnimations];
    if(self.delegate){
        [self.delegate getResult:res];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        NSString *data = metadataObject.stringValue;
        BOOL flag = false;
        if([self.type isEqualToString:@"url"] || [self.type isEqualToString:@"all"]){
            if([data hasPrefix:@"http"] || [data hasPrefix:@"https"]){
                [self getResult:data];
                flag = YES;
            }
        }
        if(flag) return;
        if([self.type isEqualToString:@"address"] || [self.type isEqualToString:@"all"]){
            if([data hasPrefix:@"ethereum:"]){
                data = [data substringFromIndex:9];
            }
            if(([data hasPrefix:@"0x"] && data.length == 42) || ([data hasPrefix:@"T"] && data.length == 34)){
                [self getResult:data];
            }
        }
    }
}

@end
