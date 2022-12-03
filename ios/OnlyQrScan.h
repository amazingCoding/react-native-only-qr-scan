
#ifdef RCT_NEW_ARCH_ENABLED
#import "RNOnlyQrScanSpec.h"

@interface OnlyQrScan : NSObject <NativeOnlyQrScanSpec>
#else
#import <React/RCTBridgeModule.h>

@interface OnlyQrScan : NSObject <RCTBridgeModule>
#endif

@end
