//
//  RNOpenCVManager.m
//  iazzuED
//
//  Created by Stephan Müller on 11/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNOpenCVManager.hh"
#import <React/RCTLog.h>
#import "UIImage+fixOrientation.h"
#import "QuadDetectionHelper.h"

using namespace cv;
using namespace std;

@implementation RNOpenCVManager
{
  
}

/*
- (dispatch_queue_t)methodQueue
{
  return dispatch_queue_create("com.iazzu.iazzu.RNOpenCVManager", DISPATCH_QUEUE_SERIAL);
}
*/

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(addEvent:(NSString *)name location:(NSString *)location)
{
  RCTLogInfo(@"Pretending to create an event %@ at %@", name, location);
}

+ (void) createSurfaceOverlay:(Mat)matSurface edr:(NSDictionary *)edr theSelector:(SEL)theSelector {
  dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){ //Background Thread
    dispatch_async(dispatch_get_main_queue(), ^(void){
      Mat ret = matSurface.clone();
      [[NSRunLoop mainRunLoop] performSelectorOnMainThread:theSelector withObject:nil waitUntilDone:false];
    });
  });
}

RCT_EXPORT_METHOD(test:(NSString *)stringToPrint
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *result = [NSString stringWithFormat:@"RNOpenCVManager.native.test (%@)", stringToPrint];
  NSLog(@"%@", result);
  resolve (result);
}


RCT_EXPORT_METHOD(saveImageToPictureRoll:(NSString *)urlImage
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSLog(@"saveImageToPictureRoll (..)");
  
  NSURL     *imageURL   = [NSURL URLWithString:urlImage];
  NSString  *path       = [imageURL path];
  NSData    *imageData  = [[NSFileManager defaultManager] contentsAtPath:path];
  UIImage   *imageRaw   = [UIImage imageWithData:imageData];
  UIImage   *image      = [imageRaw fixOrientation];
  
  UIImageWriteToSavedPhotosAlbum(image ,
                                 self, // send the message to 'self' when calling the callback
                                 @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:), // the selector to tell the method to call on completion
                                 NULL); // you generally won't need a contextInfo here);
  
  resolve (nil);
}

- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo {
  
  if (error) {
    // Do anything needed to handle the error or display it to the user
  } else {
    // .... do anything you want here to handle
    // .... when the image has been saved in the photo album
  }
}

RCT_EXPORT_METHOD (renderWall:(NSString *)     localPathSurface
             localPathArtwork:(NSString *)     localPathArtwork
                 propsSurface:(NSDictionary *) propsSurface
               cornersArtwork:(NSDictionary *) cornersArtwork
               filenameOutput:(NSString *)     filenameOutput
                  jpegQuality:(int)            jpegQuality
                  debugRender:(BOOL)           debugRender
                     resolver:(RCTPromiseResolveBlock) resolve
                     rejecter:(RCTPromiseRejectBlock)  reject) {
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    NSLog (@"RNOpenCVManager.mm.renderWall ()");
    
    @try {
      NSArray  *docDirPaths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *docDirPath  = [docDirPaths firstObject];
      NSString *pathRender  = [NSString stringWithFormat:@"%@/render", docDirPath];
      
      NSLog (@"RNOpenCVManager.mm.renderWall (), calling [RNOpenCVHelper renderWallNative]");
      StructRenderWallResult renderWallResult = [RNOpenCVHelper renderWallNative:localPathSurface
                                                          localPathArtworkString:localPathArtwork
                                                                propsSurfaceDict:propsSurface
                                                              cornersArtworkDict:cornersArtwork
                                                            filenameOutputString:filenameOutput
                                                                     jpegQuality:jpegQuality
                                                                pathRenderString:pathRender
                                                                           debug:debugRender];
      
      resolve(@{@"success": [NSNumber numberWithBool:renderWallResult.success],
                @"width":   [NSNumber numberWithInt: renderWallResult.width],
                @"height":  [NSNumber numberWithInt: renderWallResult.height],
                });
        
    } @catch (NSException *exception) {      
      // NSLog (@"Caught Exception Name: %@", exception.name);
      NSLog (@"Caught Exception Reason: %@", exception.reason); // ARTWORK_IMAGE_NOT_FOUND
      reject(exception.reason, nil, nil);
    }
  });
}

RCT_EXPORT_METHOD (createResizedImage:(NSString *)  localPath
                         sizeFullsize:(int)         sizeFullsize
                       filenameOutput:(NSString *)  filenameOutput
                          jpegQuality:(int)         jpegQuality
                             resolver:(RCTPromiseResolveBlock) resolve
                             rejecter:(RCTPromiseRejectBlock)   reject)
{
  dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog (@"RNOpenCVManager.mm.createResizedImage ()");
    
    @try {
      
      NSArray  *docDirPaths   = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *docDirPath    = [docDirPaths firstObject];
      NSString *pathSurfaces  = [NSString stringWithFormat:@"%@/surfaces", docDirPath];

      StructResizeImageResult resizeImageResult = [RNOpenCVHelper createResizedImageNative:localPath
                                                                              sizeFullsize:sizeFullsize 
                                                                      filenameOutputString:filenameOutput
                                                                          pathRenderString:pathSurfaces
                                                                               jpegQuality:jpegQuality];
      resolve(@{@"success": [NSNumber numberWithBool:resizeImageResult.success],
                @"width":   [NSNumber numberWithInt: resizeImageResult.width],
                @"height":  [NSNumber numberWithInt: resizeImageResult.height],
                });
    }
    @catch (NSException *exception) {
      NSLog (@"Caught Exception Reason: %@", exception.reason); // ARTWORK_IMAGE_NOT_FOUND
        reject(exception.reason, nil, nil);
    }
  });
}

RCT_EXPORT_METHOD (rectifyImage:(NSString *)         localPathImage
                   cornersDict:(NSDictionary *)      cornersDict
                   aspectRatio:(float)               aspectRatio
                   contrast:(float)                  contrast
                   brightness:(int)                  brightness
                   sharpness:(float)                 sharpness
                   filenameOutputString:(NSString *) filenameOutputString
                   jpegQuality:(int)                 jpegQuality
                   resolver:(RCTPromiseResolveBlock) resolve
                   rejecter:(RCTPromiseRejectBlock)  reject)
{
  dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog (@"RNOpenCVManager.mm.rectifyImage ()");
    
    @try {
      NSArray  *docDirPaths   = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
      NSString *docDirPath    = [docDirPaths firstObject];
      NSString *pathRectified = [NSString stringWithFormat:@"%@/rectified", docDirPath];
      
      StructRectifyImageResult rectifyImageResult = [RNOpenCVHelper rectifyImage:localPathImage
                                                                    cornersDict:cornersDict // already absolute, calculated in JS
                                                                    aspectRatio:aspectRatio
                                                                       contrast:contrast
                                                                     brightness:brightness
                                                                      sharpness:sharpness
                                                           filenameOutputString:filenameOutputString
                                                            pathRectifiedString:pathRectified
                                                                    jpegQuality:jpegQuality];

      resolve(@{@"success": [NSNumber numberWithBool:rectifyImageResult.success],
                @"width":   [NSNumber numberWithInt: rectifyImageResult.width],
                @"height":  [NSNumber numberWithInt: rectifyImageResult.height],
                });
    }
    @catch (NSException *exception) {
      NSLog (@"Caught Exception Reason: %@", exception.reason);
      reject (exception.reason, nil, nil);
    }
  });
}

RCT_EXPORT_METHOD (detectEdges:(NSString *)localPath
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject)
{
  dispatch_async (dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSLog (@"RNOpenCVManager.mm.detectEdges ()");
    
    @try {
      StructDetectEdgesResult detectEdgesResult = [RNOpenCVHelper detectEdges:localPath];
      
      resolve (@{ @"ctlx":  [NSNumber numberWithFloat:detectEdgesResult.ctlx],
                  @"ctly":  [NSNumber numberWithFloat:detectEdgesResult.ctly],
                  @"ctrx":  [NSNumber numberWithFloat:detectEdgesResult.ctrx],
                  @"ctry":  [NSNumber numberWithFloat:detectEdgesResult.ctry],
                  @"cbrx":  [NSNumber numberWithFloat:detectEdgesResult.cbrx],
                  @"cbry":  [NSNumber numberWithFloat:detectEdgesResult.cbry],
                  @"cblx":  [NSNumber numberWithFloat:detectEdgesResult.cblx],
                  @"cbly":  [NSNumber numberWithFloat:detectEdgesResult.cbly],
                  @"vphx": [NSNumber numberWithFloat:detectEdgesResult.vphx],
                  @"vphy": [NSNumber numberWithFloat:detectEdgesResult.vphy],
                  @"vpvx": [NSNumber numberWithFloat:detectEdgesResult.vpvx],
                  @"vpvy": [NSNumber numberWithFloat:detectEdgesResult.vpvy],
                  // @"linesImage": linesImage
                  // @"blurFactorUsed": [NSNumber numberWithInt:res.blurFactorUsed],
                  });
    }
    @catch (NSException *exception) {
      NSLog (@"Caught Exception Reason: %@", exception.reason);
      reject (exception.reason, nil, nil);
    }
  });
}


#pragma mark - Terminal -> Objective-C Specific Functions
void    SaveMaterialWithPostfix ( Mat toSave, char* path_output, char* filename, const char* postfix ) {
  
  if (!saveFilePostfix(postfix))
    return;
  
  NSString *filenameSTR = [NSString stringWithUTF8String:filename];
  NSString *postfixSTR = [NSString stringWithUTF8String:postfix];
  NSString *filenameFinale = [NSString stringWithFormat:@"%@_%@", filenameSTR, postfixSTR];
  [RNOpenCVManager saveMatAsJPEG:toSave filename:filenameFinale quality:1.0];

  NSLog(@"TEST");
  //sleep(10);
}

#pragma mark - Helper Methods

+ (NSDictionary *) createResizedJPEG:(NSString *)localPath
                        sizeFullsize:(int)sizeFullsize
                             quality:(float)quality
{
  NSString *path = [[NSURL URLWithString:localPath] path];
  UIImage  *image = [[UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:path]] fixOrientation];
  
  NSString *imageFilename = [path lastPathComponent];
  NSString *imageFilenameNoExt = [imageFilename stringByDeletingPathExtension];
  
  NSString *dstFullsizeFilename = [NSString stringWithFormat:@"%@_%d.jpg", imageFilenameNoExt, sizeFullsize];
  NSString *resizedURL = [[RNOpenCVManager getOpenCVDirectory] stringByAppendingPathComponent:dstFullsizeFilename];
  
  int srcWidth  = image.size.width;
  int srcHeight = image.size.height;
  
  double resizeFactor = getResizeFactor (srcWidth, srcHeight, sizeFullsize);
  
  int newWidth  = round (resizeFactor * (float)srcWidth);
  int newHeight = round (resizeFactor * (float)srcHeight);
  
  if (![[NSFileManager defaultManager] fileExistsAtPath:resizedURL]){
    Mat       src         = [RNOpenCVManager cvMatFromUIImage:image];
    Mat       srcFullsize = resizeMat (src, newWidth, newHeight);
    [RNOpenCVManager saveMatAsJPEG:srcFullsize filename:dstFullsizeFilename quality:quality];
  }
  return(@{
            @"resizedURL": resizedURL,
            @"resizedWidth": [NSNumber numberWithInt:newWidth],
            @"resizedHeight": [NSNumber numberWithInt:newHeight],
            @"srcFilenameNoExt": imageFilenameNoExt,
            @"srcWidth": [NSNumber numberWithInt:srcWidth],
            @"srcHeight": [NSNumber numberWithInt:srcHeight],
            @"resizeFactor": [NSNumber numberWithDouble:resizeFactor],
            });
}

+ (void) saveMatAsJPEG:(Mat)material
              filename:(NSString *)filename
               quality:(float)quality
{
  NSString *fullURL = [[RNOpenCVManager getOpenCVDirectory] stringByAppendingPathComponent:filename];
  UIImage*  dstFullsize = [RNOpenCVManager UIImageFromCVMat:material];
  [UIImageJPEGRepresentation(dstFullsize, quality) writeToFile:fullURL atomically:YES];
}

+ (NSString *) getOpenCVDirectory {
  
  NSArray  *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDir  = [documentPaths objectAtIndex:0];
  NSString *outputPath    = [documentsDir stringByAppendingPathComponent:@"opencv"];
  return outputPath;
}


+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
  
  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
  //cv::Mat cvMat(rows, cols, CV_8UC3); // 8 bits per component, 3 channels (color channels)
  
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                  cols,                       // Width of bitmap
                                                  rows,                       // Height of bitmap
                                                  8,                          // Bits per component
                                                  cvMat.step[0],              // Bytes per row
                                                  colorSpace,                 // Colorspace
                                                  kCGImageAlphaNoneSkipLast |
                                                  kCGBitmapByteOrderDefault); // Bitmap info flags
  
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  
  return cvMat;
}
+ (Mat)cvMatGrayFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
  cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
  
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                  cols,                       // Width of bitmap
                                                  rows,                       // Height of bitmap
                                                  8,                          // Bits per component
                                                  cvMat.step[0],              // Bytes per row
                                                  colorSpace,                 // Colorspace
                                                  kCGImageAlphaNoneSkipLast |
                                                  kCGBitmapByteOrderDefault); // Bitmap info flags
  
  CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease(contextRef);
  
  return cvMat;
}
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
  NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
  CGColorSpaceRef colorSpace;
  
  if (cvMat.elemSize() == 1) {
    colorSpace = CGColorSpaceCreateDeviceGray();
  } else {
    colorSpace = CGColorSpaceCreateDeviceRGB();
  }
  
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  
  // Creating CGImage from cv::Mat
  CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                      cvMat.rows,                                 //height
                                      8,                                          //bits per component
                                      8 * cvMat.elemSize(),                       //bits per pixel
                                      cvMat.step[0],                            //bytesPerRow
                                      colorSpace,                                 //colorspace
                                      kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                      provider,                                   //CGDataProviderRef
                                      NULL,                                       //decode
                                      false,                                      //should interpolate
                                      kCGRenderingIntentDefault                   //intent
                                      );
  
  
  // Getting UIImage from CGImage
  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  CGDataProviderRelease(provider);
  CGColorSpaceRelease(colorSpace);
  
  return finalImage;
}


@end
