#import <Foundation/Foundation.h>
#import <React/RCTLog.h>
#import "RNSKOpenCVModule.hh"
// #import "UIImage+fixOrientation.h"
// #import "QuadDetectionHelper.h"

#import <opencv2/opencv.hpp> // requires Prefix Header File

// using namespace cv;
// using namespace std;

@implementation RNSKOpenCVModule {}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD (test:(NSString *)platform
                     resolver:(RCTPromiseResolveBlock) resolve
                     rejecter:(RCTPromiseRejectBlock)  reject) {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    NSLog (@"RNSKOpenCVModule.mm.test()");
    
    @try {
      NSArray  *docDirPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *docDirPath  = [docDirPaths firstObject];
      NSString *pathRender  = [NSString stringWithFormat:@"%@/render", docDirPath];
      
      NSString *openCvVersion = [NSString stringWithFormat:@"%s", CV_VERSION];
      resolve(@{@"success": [NSNumber numberWithBool:true],
                @"platform": [NSString stringWithString:platform],
                @"pathRender": [NSString stringWithString:pathRender],
                @"openCvVersion": [NSString stringWithString:openCvVersion],
                });
        
    } @catch (NSException *exception) {      
      // NSLog (@"Caught Exception Name: %@", exception.name);
      NSLog (@"Caught Exception Reason: %@", exception.reason); // ARTWORK_IMAGE_NOT_FOUND
      reject(exception.reason, nil, nil);
    }
  });
}

@end
