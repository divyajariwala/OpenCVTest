#include <android/log.h>

#include <jni.h>
#include <string>
#include <stdio.h>
#include <string.h>
#include <stdexcept>
#include <dirent.h>
#include <unistd.h>
#include <iostream>
#include <sstream>
#include <algorithm>
#include <cmath>

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/highgui/highgui.hpp>

using namespace std;
using namespace cv;

#define LOG_TAG "native-lib"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define PLATFORM_OPENCV_ANDROID
#ifdef PLATFORM_OPENCV_ANDROID
  #define printf(...) __android_log_print (ANDROID_LOG_DEBUG, "SKOpenCv", __VA_ARGS__);
#endif

typedef struct {
  int testInt;
} StructTestResult, *pStructTestResult;

typedef struct {
  int testInt;
  char* testString;
} StructTestWithStringResult, *pStructTestWithStringResult;

extern "C"
{
  // StructTestResult
  jclass STRUCT_TEST_RESULT;
  jmethodID STRUCT_TEST_RESULT_CONSTRUCTOR;
  jfieldID STRUCT_TEST_RESULT_TESTINT;

  // StructTestWithStringResult
  jclass STRUCT_TEST_WITH_STRING_RESULT;
  jmethodID STRUCT_TEST_WITH_STRING_RESULT_CONSTRUCTOR;
  jfieldID STRUCT_TEST_WITH_STRING_RESULT_TESTINT;
  jfieldID STRUCT_TEST_WITH_STRING_RESULT_TESTSTRING;

  jclass JAVA_EXCEPTION;

  jint JNI_OnLoad (JavaVM *vm, void *reserved) { // called once onLoad
    JNIEnv *env;

    if (vm->GetEnv((void **) (&env), JNI_VERSION_1_6) != JNI_OK) {
      return -1;
    }

    // StructTestResult
    STRUCT_TEST_RESULT              = (jclass) env->NewGlobalRef (env->FindClass("com/skizzo/opencv/StructTestResult"));
    STRUCT_TEST_RESULT_CONSTRUCTOR  = env->GetMethodID (STRUCT_TEST_RESULT, "<init>", "(I)V");
    STRUCT_TEST_RESULT_TESTINT      = env->GetFieldID (STRUCT_TEST_RESULT, "testInt", "I");

    // StructTestWithStringResult
    STRUCT_TEST_WITH_STRING_RESULT              = (jclass) env->NewGlobalRef (env->FindClass("com/skizzo/opencv/StructTestWithStringResult"));
    STRUCT_TEST_WITH_STRING_RESULT_CONSTRUCTOR  = env->GetMethodID (STRUCT_TEST_WITH_STRING_RESULT, "<init>", "(ILjava/lang/String;)V");
    STRUCT_TEST_WITH_STRING_RESULT_TESTINT      = env->GetFieldID (STRUCT_TEST_WITH_STRING_RESULT, "testInt", "I");
    STRUCT_TEST_WITH_STRING_RESULT_TESTSTRING   = env->GetFieldID (STRUCT_TEST_WITH_STRING_RESULT, "testString", "Ljava/lang/String;");

    // Exception
    JAVA_EXCEPTION = (jclass)env->NewGlobalRef (env->FindClass("java/lang/Exception"));

    return JNI_VERSION_1_6;
  }

  jobject JNICALL Java_com_skizzo_opencv_RNSKOpenCVNativeClass_test (JNIEnv *env, jobject instance, jstring platform) {
    const char* platformStr = env->GetStringUTFChars (platform, NULL);
    LOGD("platformStr: %s", platformStr); // "android"

    StructTestResult testResult;
    testResult.testInt = 123; // int -> OK

    // turn the C struct back into a jobject and return it
    return env->NewObject(STRUCT_TEST_RESULT, STRUCT_TEST_RESULT_CONSTRUCTOR, testResult.testInt);
  }

  jobject JNICALL Java_com_skizzo_opencv_RNSKOpenCVNativeClass_testWithString (JNIEnv *env, jobject instance, jstring platform) {
    const char* platformStr = env->GetStringUTFChars (platform, NULL);
    LOGD("platformStr: %s", platformStr); // "android"

    StructTestWithStringResult testWithStringResult;
    testWithStringResult.testInt = 456; // int -> OK

    // char* openCvVersion = CV_VERSION;
    // LOGD("openCvVersion: %s", openCvVersion);

    // testWithStringResult.testString = CV_VERSION; // adding this line produces the crash

    // turn the C struct back into a jobject and return it
    return env->NewObject(STRUCT_TEST_WITH_STRING_RESULT, STRUCT_TEST_WITH_STRING_RESULT_CONSTRUCTOR, testWithStringResult.testInt, testWithStringResult.testString);
  }

}