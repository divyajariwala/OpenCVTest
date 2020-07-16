package com.skizzo.opencv;

import com.facebook.react.bridge.ReadableMap;

public class RNSKOpenCVNativeClass {
  public native static StructTestResult test(final String platform); // success
  public native static StructTestWithStringResult testWithString(final String platform); // error
}