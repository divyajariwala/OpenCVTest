//
//  RNOpenCV.h
//  iazzuED
//
//  Created by Stephan Müller on 11/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import "RNOpenCVHelper.hh"
#import "QuadDetectionHelper.h"

@interface RNOpenCVManager : NSObject <RCTBridgeModule>

+ (NSString *) getOpenCVDirectory;

+ (void) createSurfaceOverlay:(cv::Mat)matSurface edr:(NSDictionary *)edr theSelector:(SEL)theSelector;

@end
