//
//  RNSKOpenCVManager.h
//  iazzuED
//
//  Created by Stephan Müller on 09/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <React/RCTViewManager.h>
#import "RNOpenCVView.hh"

@interface RNOpenCVViewManager : RCTViewManager
  @property (nonatomic, assign) NSString *src;

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

@end
