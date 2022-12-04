#import "OnlyQrScan.h"
#import <React/RCTUtils.h>
#import "ScanViewController.h"
@interface OnlyQrScan()<ScanViewControllerDelegate>
@property (nonatomic, strong)RCTPromiseResolveBlock resolve;
@property (nonatomic, strong)RCTPromiseRejectBlock reject;
@end
@implementation OnlyQrScan
RCT_EXPORT_MODULE()

RCT_REMAP_METHOD(openQRScan,
                 multiplyWith:(NSString *)mainColor withType:(NSString *)type withErrorTitle:(NSString *)title withErrorContent:(NSString *)content
                 withConfirmText:(NSString *)confirmText withCancelText:(NSString *)cancelText
                 withResolver:(RCTPromiseResolveBlock)resolve
                 withRejecter:(RCTPromiseRejectBlock)reject){
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(self.reject || self.reject){
            reject(@"-100",@"Duplicate declaration",nil);
            return;
        }
        UIViewController* vc = RCTPresentedViewController();
        ScanViewController *scanQRVc = [[ScanViewController alloc] init];
        scanQRVc.preVc = vc;
        scanQRVc.type = type;
        scanQRVc.mainColor = mainColor;
        scanQRVc.confirmText = confirmText;
        scanQRVc.cancelText = cancelText;
        scanQRVc.errorTitle = title;
        scanQRVc.errorContent = content;
        scanQRVc.modalPresentationStyle = UIModalPresentationFullScreen;
        self.reject = reject;
        self.resolve = resolve;
        scanQRVc.delegate = self;
        [vc presentViewController:scanQRVc animated:YES completion:nil];
    }];
}
- (void)getError:(nonnull NSString *)error {
    _reject(@"-1",error,nil);
    _resolve = nil;
    _reject = nil;
}

- (void)getResult:(nonnull NSString *)result {
    _resolve(result);
    _resolve = nil;
    _reject = nil;
}

// Don't compile this code when we build for the old architecture.
#ifdef RCT_NEW_ARCH_ENABLED
- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:
    (const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeOnlyQrScanSpecJSI>(params);
}
#endif

@end


