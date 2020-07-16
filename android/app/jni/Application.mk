# Android makefile for textsort shared lib, jni wrapper around libtextsort C API

APP_ABI := all
APP_OPTIM := release
APP_PLATFORM := android-8

# GNU libc++ is the only Android STL which supports C++11 features - NEEDS to be gnustl_static / NDK version 16
APP_STL := gnustl_static
APP_CPPFLAGS := -std=c++11

# APP_BUILD_SCRIPT := jni/Android.mk
# LOCAL_ALLOW_UNDEFINED_SYMBOLS := true
