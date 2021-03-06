//
//  RNSKOpenCV.h
//
//  Created by Stephan Müller on 09/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <React/RCTComponent.h>
#import <UIKit/UIKit.h>
#import <React/RCTEventDispatcher.h>

#define NOT_IN_TERMINAL true

@interface RNOpenCVView : UIView

  - (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

  @property (nonatomic, copy) RCTBubblingEventBlock onCVError;

@end
