import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-only-qr-scan' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const OnlyQrScan = NativeModules.OnlyQrScan
  ? NativeModules.OnlyQrScan
  : new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );
export const QR_SCAN_EVENT = 'QR_SCAN_EVENT';
export type QR_SCAN_TYPE = 'address' | 'url' | 'all'
interface ErrorTip {
  title: string;
  content: string;
  confirmText: string;
  cancelText: string;
}
export function openQRScan(mainColor: string, type: QR_SCAN_TYPE, error: ErrorTip): Promise<string> {
  return OnlyQrScan.openQRScan(mainColor, type, error.title, error.content, error.confirmText, error.cancelText);
}
