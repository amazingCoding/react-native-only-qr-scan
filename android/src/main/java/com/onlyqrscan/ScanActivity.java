package com.onlyqrscan;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.camera.core.CameraSelector;
import androidx.camera.core.ImageAnalysis;
import androidx.camera.core.ImageProxy;
import androidx.camera.core.Preview;
import androidx.camera.lifecycle.ProcessCameraProvider;
import androidx.camera.view.PreviewView;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.lifecycle.LifecycleOwner;

import android.Manifest;
import android.annotation.SuppressLint;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.media.Image;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.util.Size;
import android.view.View;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.mlkit.vision.barcode.BarcodeScanner;
import com.google.mlkit.vision.barcode.BarcodeScannerOptions;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.common.InputImage;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class ScanActivity extends AppCompatActivity {
  private static final int PERMISSION_CAMERA_REQUEST_CODE = 0x00000012;
  private final static String TAG = "ScanQRActivity";
  private PreviewView previewView;
  private ListenableFuture<ProcessCameraProvider> cameraProviderFuture;
  private BarcodeScanner scanner;
  private ExecutorService cameraExecutor;
  private View scanLine;
  private class MyAnalyzer implements ImageAnalysis.Analyzer {


    @SuppressLint("UnsafeOptInUsageError")
    @Override
    public void analyze(@NonNull ImageProxy imageProxy) {
      final Image mediaImage = imageProxy.getImage();
      if(mediaImage != null){
        InputImage image = InputImage.fromMediaImage(mediaImage, imageProxy.getImageInfo().getRotationDegrees());
        Task<List<Barcode>> result = scanner.process(image)
          .addOnSuccessListener(new OnSuccessListener<List<Barcode>>() {
            @Override
            public void onSuccess(List<Barcode> barcodes) {
              boolean flag = false;
              for (Barcode barcode:barcodes){
                String rawValue = barcode.getRawValue();
                int valueType = barcode.getValueType();
                Log.d(TAG,rawValue);

                // check is ethereum address
                if(rawValue != null){
                  // if rawValue start with 'ethereum:' ,remove it
                  if(rawValue.startsWith("ethereum:")){
                    rawValue = rawValue.substring(9);
                  }
                  if (rawValue.startsWith("0x") && rawValue.length() == 42){
                    flag = true;
                    Intent intent = new Intent();
                    intent.putExtra("result",rawValue);
                    setResult(RESULT_OK,intent);
                    finish();
                  }

                  // check rawValue is a valid url
                  if(rawValue.startsWith("http://") || rawValue.startsWith("https://")){
                    flag = true;
                    Intent intent = new Intent();
                    intent.putExtra("result",rawValue);
                    setResult(RESULT_OK,intent);
                    finish();
                  }

                  // check rawValue is a tron address
                  if(rawValue.startsWith("T") && rawValue.length() == 34){
                    flag = true;
                    Intent intent = new Intent();
                    intent.putExtra("result",rawValue);
                    setResult(RESULT_OK,intent);
                    finish();
                  }
                }

              }
              if(!flag)  imageProxy.close();
            }
          })
          .addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
              imageProxy.close();
            }
          });
        return;
      }
      imageProxy.close();
    }
  }
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_scan);
    getWindow().clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
    getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_STABLE);
    getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS | WindowManager.LayoutParams.FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
    getWindow().setStatusBarColor(Color.TRANSPARENT);
    getWindow().setNavigationBarColor(Color.BLACK);
    LinearLayout closeBtn = findViewById(R.id.cloesBtn);
    int dp20 = dp2px(20);
    int dp36 = dp2px(36);
    setView();
    LinearLayout.LayoutParams layoutParams = new LinearLayout.LayoutParams(dp36,dp36);
    layoutParams.setMargins(dp20,dp20 + getStatusBarHeightCompat(),0,0);
    closeBtn.setLayoutParams(layoutParams);
    closeBtn.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        setResult(RESULT_CANCELED);
        finish();
      }
    });
    checkPermissionAndCamera();

  }
  private void setView(){
    View scanLine_1 = findViewById(R.id.scan_line_1);
    View scanLine_2 = findViewById(R.id.scan_line_2);
    View scanLine_3 = findViewById(R.id.scan_line_3);
    View scanLine_4 = findViewById(R.id.scan_line_4);
    View scanLine_5 = findViewById(R.id.scan_line_5);
    View scanLine_6 = findViewById(R.id.scan_line_6);
    View scanLine_7 = findViewById(R.id.scan_line_7);
    View scanLine_8 = findViewById(R.id.scan_line_8);
    View scanLine = findViewById(R.id.scanLine);

    // get color string from intent
    String color = getIntent().getStringExtra("color");
    if(color != null){
      int colorInt = Color.parseColor(color);
      scanLine_1.setBackgroundColor(colorInt);
      scanLine_2.setBackgroundColor(colorInt);
      scanLine_3.setBackgroundColor(colorInt);
      scanLine_4.setBackgroundColor(colorInt);
      scanLine_5.setBackgroundColor(colorInt);
      scanLine_6.setBackgroundColor(colorInt);
      scanLine_7.setBackgroundColor(colorInt);
      scanLine_8.setBackgroundColor(colorInt);
      scanLine.setBackgroundColor(colorInt);
    }
    TextView errTitle = findViewById(R.id.errTitle);
    TextView errorText = findViewById(R.id.errText);
    TextView cancelText = findViewById(R.id.cancelText);
    TextView goToSettingText = findViewById(R.id.goToSettingText);

    // get title and text from intent
    String title = getIntent().getStringExtra("title");
    String text = getIntent().getStringExtra("content");
    String cancel = getIntent().getStringExtra("cancelText");
    String goToSetting = getIntent().getStringExtra("confirmText");
    if(title != null){
      errTitle.setText(title);
    }
    if(text != null){
      errorText.setText(text);
    }
    if(cancel != null){
      cancelText.setText(cancel);
    }
    if(goToSetting != null){
      goToSettingText.setText(goToSetting);
    }
  }
  public int getStatusBarHeightCompat() {
    int result = 0;
    int resId = this.getResources().getIdentifier("status_bar_height", "dimen", "android");
    if (resId > 0) {
      result = this.getResources().getDimensionPixelOffset(resId);
    }
    return result;
  }
  public int dp2px(int dp){
    //获取手机密度
    float density = this.getResources().getDisplayMetrics().density;
    return (int) (dp * density + 0.5);//实现四舍五入
  }
  private void checkPermissionAndCamera() {
    int hasCameraPermission = ContextCompat.checkSelfPermission(getApplication(), Manifest.permission.CAMERA);
    if (hasCameraPermission == PackageManager.PERMISSION_GRANTED) {
      init();
    }
    else {
      //没有权限，申请权限。
      ActivityCompat.requestPermissions(this,new String[]{Manifest.permission.CAMERA}, PERMISSION_CAMERA_REQUEST_CODE);
    }
  }
  /**
   * 处理权限申请的回调。
   */
  @Override
  public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults);
    if (requestCode == PERMISSION_CAMERA_REQUEST_CODE) {
      if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
        //允许权限，有调起相机拍照。
        init();
      }
      else {
        //拒绝权限，弹出提示框。
        View view =  findViewById(R.id.errBox);
        LinearLayout cancel = findViewById(R.id.cancel);
        LinearLayout goToSetting = findViewById(R.id.goToSetting);
        cancel.setOnClickListener(new View.OnClickListener() {
          @Override
          public void onClick(View v) {
            setResult(RESULT_CANCELED);
            finish();
          }
        });
        goToSetting.setOnClickListener(new View.OnClickListener() {
          @Override
          public void onClick(View v) {
            Context context = ScanActivity.this;
            Intent mIntent = new Intent();
            mIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            mIntent.setAction("android.settings.APPLICATION_DETAILS_SETTINGS");
            mIntent.setData(Uri.fromParts("package", context.getPackageName(), null));
            context.startActivity(mIntent);
            setResult(RESULT_CANCELED);
            finish();
          }
        });
        view.setVisibility(View.VISIBLE);
      }
    }
  }

  private void init(){
    previewView = findViewById(R.id.previewView);
    cameraProviderFuture = ProcessCameraProvider.getInstance(this);
    cameraProviderFuture.addListener(() -> {
      try {
        ProcessCameraProvider cameraProvider = cameraProviderFuture.get();
        bindPreview(cameraProvider);
      } catch (ExecutionException | InterruptedException e) {
      }
    }, ContextCompat.getMainExecutor(this));
  }
  private void bindPreview(ProcessCameraProvider cameraProvider){
    scanLine = findViewById(R.id.scanLine);
    TranslateAnimation translateAnimation = new TranslateAnimation(0,0,0,dp2px(192));
    translateAnimation.setDuration(2000);
    translateAnimation.setRepeatCount(Animation.INFINITE);
    translateAnimation.setFillAfter(true);
    scanLine.startAnimation(translateAnimation);

    Preview preview = new Preview.Builder().build();
    ImageAnalysis imageAnalysis = new ImageAnalysis.Builder()
      .setTargetResolution(new Size(1280, 720))
      .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
      .build();
    cameraExecutor = Executors.newSingleThreadExecutor();
    BarcodeScannerOptions options = new BarcodeScannerOptions.Builder().setBarcodeFormats(Barcode.FORMAT_QR_CODE).build();
    scanner = BarcodeScanning.getClient(options);
    imageAnalysis.setAnalyzer(cameraExecutor,new MyAnalyzer());
    CameraSelector cameraSelector = new CameraSelector.Builder()
      .requireLensFacing(CameraSelector.LENS_FACING_BACK)
      .build();
    preview.setSurfaceProvider(previewView.getSurfaceProvider());
    cameraProvider.bindToLifecycle((LifecycleOwner)this, cameraSelector,imageAnalysis, preview);
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if(scanLine != null) scanLine.animate().cancel();
    if(cameraExecutor != null) cameraExecutor.shutdown();
  }

  @Override
  public void finish() {
    super.finish();
    overridePendingTransition(R.anim.normal_bottom,R.anim.pop_bootom);
  }
}
