package com.skizzo.opencv;

import android.app.Activity;
import android.app.Application;
import android.content.Intent;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Environment;
import android.os.AsyncTask;
import android.provider.Settings;
import android.util.Log;
import android.widget.Toast;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Promise;

import org.opencv.android.BaseLoaderCallback;
import org.opencv.android.LoaderCallbackInterface;
import org.opencv.android.OpenCVLoader;
import org.opencv.core.Mat;
import org.opencv.imgcodecs.Imgcodecs;

import java.io.File;
import java.io.FileFilter;
import java.io.IOException;
import java.util.logging.FileHandler;

public class RNSKOpenCVModule extends ReactContextBaseJavaModule {
  private static ReactApplicationContext reactContext;

  RNSKOpenCVModule(ReactApplicationContext context) {
    super(context);
    reactContext = context;
  }
  static {
    System.loadLibrary("native-lib"); // native-lib.cpp
  }

  @Override
  public String getName() {
    Log.w ("opencvtest", "RNSKOpenCVModule.java getName() called");
    return "RNSKOpenCVModule"; // NativeModules.RNSKOpenCVModule
  }

  @ReactMethod
  public void test(final String platform, final Promise promise) {
    Activity currentActivity = getCurrentActivity();
    if (currentActivity == null) {
        promise.reject("Activity doesn't exist.");
        return;
    }
    Log.w("RNSKOpenCVModule", "RNSKOpenCVModule.java.test()");
    Runnable runnable = new Runnable() {
      @Override
      public void run() {
        try {
          StructTestResult testResult = RNSKOpenCVNativeClass.test(platform);
          WritableMap res = testResult.toWritableMap(); 
          promise.resolve(res);
        }
        catch (Exception e) {
          promise.reject("ERR", e);
        }
      }
    };
    AsyncTask.execute(runnable);
  }

  @ReactMethod
  public void testWithString(final String platform, final Promise promise) {
    Activity currentActivity = getCurrentActivity();
    if (currentActivity == null) {
      promise.reject("Activity doesn't exist.");
      return;
    }
    Log.w("RNSKOpenCVModule", "RNSKOpenCVModule.java.testWithString()");
    Runnable runnable = new Runnable() {
      @Override
      public void run() {
        try {
          StructTestWithStringResult testWithStringResult = RNSKOpenCVNativeClass.testWithString(platform);
          WritableMap res = testWithStringResult.toWritableMap(); 
          promise.resolve(res);
        }
        catch (Exception e) {
          promise.reject("ERR", e);
        }
      }
    };
    AsyncTask.execute(runnable);
  }

}
