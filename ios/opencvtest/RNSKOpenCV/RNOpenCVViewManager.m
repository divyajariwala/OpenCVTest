//
//  RNSKOpenCVManager.m
//
//  Created by Stephan Müller on 09/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import <React/RCTViewManager.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTEventEmitter.h>

#import "RNOpenCVViewManager.h"
#import "RNOpenCVView.hh"

@implementation RNOpenCVViewManager
{
  RNOpenCVView *theView;
}

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (dispatch_queue_t) methodQueue {
  return dispatch_queue_create("com.skizzo.iazzu", DISPATCH_QUEUE_SERIAL);
}

RCT_EXPORT_VIEW_PROPERTY (localPathSurface, NSString)
RCT_EXPORT_VIEW_PROPERTY (propsArtwork, NSDictionary) // URL and corners in one NSDictionary (Obj-C) / Object (JS)
RCT_EXPORT_VIEW_PROPERTY (propsSurface, NSDictionary) // color info (hue, saturation, lightness)
RCT_EXPORT_VIEW_PROPERTY (forceArtworkHidden, BOOL)
RCT_EXPORT_VIEW_PROPERTY (alphaArtwork, float)

- (UIView *)view {
  theView = [[RNOpenCVView alloc] initWithEventDispatcher:self.bridge.eventDispatcher];
  theView.backgroundColor = [UIColor redColor];
  return theView;
}

@end
