package com.skizzo.opencv;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

public class StructTestWithStringResult {

  int testInt;
  String testString;

  public StructTestWithStringResult () {}

  public StructTestWithStringResult (int testInt, String testString) {
    this.testInt = testInt;
    // this.testString = "testFromJavaConstructor"; // success
    this.testString = testString; // error
  }

  public StructTestWithStringResult (ReadableMap map) {
    this (
      (int)map.getDouble("testInt"),
      map.getString("testString")
    );
  }

  public WritableMap toWritableMap() {
    WritableMap map = Arguments.createMap();
    map.putInt("testInt", this.testInt);
    map.putString("testString", this.testString);
    return map;
  }
}
