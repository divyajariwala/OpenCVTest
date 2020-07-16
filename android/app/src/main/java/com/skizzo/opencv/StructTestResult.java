package com.skizzo.opencv;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

public class StructTestResult {

  int testInt;

  public StructTestResult () {}

  public StructTestResult (int testInt) {
    this.testInt = testInt;
  }

  public StructTestResult (ReadableMap map) {
    this (
      (int)map.getDouble("testInt")
    );
  }

  public WritableMap toWritableMap() {
    WritableMap map = Arguments.createMap();
    map.putInt("testInt", this.testInt);
    return map;
  }
}