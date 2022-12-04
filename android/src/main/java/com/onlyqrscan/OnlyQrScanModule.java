package com.onlyqrscan;

import android.app.Activity;
import android.content.Intent;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.BaseActivityEventListener;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.module.annotations.ReactModule;

@ReactModule(name = OnlyQrScanModule.NAME)
public class OnlyQrScanModule extends ReactContextBaseJavaModule {
  public static final String NAME = "OnlyQrScan";
  private Promise QRScanPromise;
  private final ActivityEventListener mActivityEventListener = new BaseActivityEventListener() {

    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
      if (requestCode == 1) {
        if (QRScanPromise != null) {
          if (resultCode == Activity.RESULT_CANCELED) {
            QRScanPromise.reject("Cancelled", "User cancelled scan");
          } else if (resultCode == Activity.RESULT_OK) {
            String res = intent.getStringExtra("result");
            QRScanPromise.resolve(res);
          }

          QRScanPromise = null;
        }
      }
    }
  };
  public OnlyQrScanModule(ReactApplicationContext reactContext) {
    super(reactContext);
    reactContext.addActivityEventListener(mActivityEventListener);
  }

  @Override
  @NonNull
  public String getName() {
    return NAME;
  }


  @ReactMethod
  public void openQRScan(String color,String type,String title,String content,String confirmText,String cancelText, Promise promise) {
    Activity currentActivity = getCurrentActivity();
    if (currentActivity != null) {
      Intent intent = new Intent(currentActivity, ScanActivity.class);
      intent.putExtra("type",type);
      intent.putExtra("color",color);
      intent.putExtra("title",title);
      intent.putExtra("content",content);
      intent.putExtra("confirmText",confirmText);
      intent.putExtra("cancelText",cancelText);
      currentActivity.startActivityForResult(intent, 1);
      currentActivity.overridePendingTransition(R.anim.push_bottom, R.anim.normal_bottom);
      QRScanPromise = promise;
    }
  }
}
