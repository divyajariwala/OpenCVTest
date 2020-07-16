//
//  RNSKOpenCV.m
//  iazzuED
//
//  Created by Stephan Müller on 09/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImage+fixOrientation.h"
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>

#import "RNOpenCVView.hh"
#import "RNOpenCVHelper.hh"
#import "RNOpenCVManager.hh"
#include "QuadDetectionHelper.h"

@implementation RNOpenCVView
{
  RCTEventDispatcher *_eventDispatcher;
  
  NSString    *urlSurface;
  cv::Mat      matSurface;
  CGSize       surfaceSize;
  UIImageView *imageViewSurface;
  
  NSString    *urlArtwork;
  cv::Mat      matArtwork;
  CGSize       artworkSize;
  UIImageView *imageViewArtwork;
  
  NSDictionary *cornersArtwork;
  
  NSDictionary *propsArtwork;
  Mat homography;
  NSDictionary *propsSurface;
  
  //UIImageView *imageViewDebug;
  
  //NSDictionary* edr;  // edgeDetectionResult
  //NSDictionary* cu;  // cornersUser
  
  BOOL artworkHidden;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
  self = [super init];
  
  if (self != nil) {
    _eventDispatcher = eventDispatcher;
    
    imageViewSurface = [[UIImageView alloc] init];
    imageViewSurface.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.0];
    [self addSubview:imageViewSurface];
    
    imageViewArtwork = [[UIImageView alloc] init];
    imageViewArtwork.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.0];
    [self addSubview:imageViewArtwork];
    
    [imageViewArtwork setAlpha:1];
    artworkHidden = false;
  }
  
  return self;
}

#pragma mark - SETTERS

- (void) setCornersArtwork:(NSDictionary *) cornersArtworkParam
     refreshViewAfterwards:(BOOL) refreshViewAfterwards
{
  if (([cornersArtworkParam isEqualToDictionary:cornersArtwork]))
    return;
  
  cornersArtwork = [NSDictionary dictionaryWithDictionary:cornersArtworkParam];
 
  RCTLog(@"setCornersArtwork (..)");
  
  if (refreshViewAfterwards)
    [self refreshView];
}

- (void) setPropsArtwork:(NSDictionary *) propsArtworkParam
{
  if (([propsArtworkParam isEqualToDictionary:propsArtwork]))
    return;
  
  if (propsArtworkParam == nil) {
   NSLog(@"propsArtworkParam == nil");
   return;
  }
  
  BOOL onlyCornersChanged = ([[propsArtworkParam valueForKey:@"localPathArtwork"] isEqualToString:[propsArtwork valueForKey:@"localPathArtwork"]]);
  
  propsArtwork = [NSDictionary dictionaryWithDictionary:propsArtworkParam]; // props artwork == what?
  NSLog(@"setPropsArtwork (..): %@", propsArtwork);
  
  NSDictionary *cornersArtworkParam = [propsArtworkParam valueForKey:@"cornersArtwork"];
  
  if (onlyCornersChanged) {
    //  means, the image is the same.
    RCTLog(@"ONLY CORNERS CHANGED");
    [self setCornersArtwork:cornersArtworkParam refreshViewAfterwards:YES];
  }
  else {
    //  means, the image changed!
    RCTLog(@"ARTWORK IMAGE CHANGED");
    [UIView animateWithDuration:0.5f animations:^{
      [imageViewArtwork setAlpha:0];
    } completion:^(BOOL finished) {
      [self setCornersArtwork:cornersArtworkParam refreshViewAfterwards:NO];
      NSString *paramLocalPathArtwork = [propsArtwork valueForKey:@"localPathArtwork"];
      [self setLocalPathArtwork:paramLocalPathArtwork refreshViewAfterwards:YES];
    }];
  }
}

// propsSurface:
//   hue: -255 .. 255
//   saturation: -255 .. 255
//   lightness: -255 .. 255
- (void) setPropsSurface:(NSDictionary *) propsSurfaceParam
{
  if (([propsSurfaceParam isEqualToDictionary:propsSurface]))
    return;
  
  if (propsSurfaceParam == nil) {
    NSLog(@"propsSurfaceParam == nil");
  }
 
  propsSurface = [NSDictionary dictionaryWithDictionary:propsSurfaceParam];
  NSLog(@"setPropsSurface (..)");

  [self refreshView];
}

- (void)setLocalPathSurface:(NSString *)paramLocalPathSurface {
  
  if ([urlSurface isEqualToString:paramLocalPathSurface])
    return;
 
  urlSurface = paramLocalPathSurface;
  
  RCTLog(@"setLocalPathSurface (%@)", urlSurface);
  
  NSURL     *imageURL   = [NSURL URLWithString:urlSurface];
  NSString  *path       = [imageURL path];
  NSData    *imageData  = [[NSFileManager defaultManager] contentsAtPath:path];
  UIImage   *imageRaw   = [UIImage imageWithData:imageData];
  UIImage   *image      = [imageRaw fixOrientation];
  
  surfaceSize = CGSizeMake(image.size.width, image.size.height);
  
  if (surfaceSize.width == 0 || surfaceSize.height == 0) {
    [_eventDispatcher sendDeviceEventWithName:@"RNOpenCVEvent" body:@{
                                                                      @"type": @"error",
                                                                      @"errorCode": @"SURFACE_IMAGE_NOT_FOUND",
                                                                      @"localPath": urlSurface,
                                                                      }];
    return;
  }
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    cv::Mat matSurfaceCreated  = [RNOpenCVHelper cvMatFromUIImage:image]; // because of fixOrientation
    dispatch_sync(dispatch_get_main_queue(), ^{
      matSurface = matSurfaceCreated.clone();
      [self refreshView];
   });
  });
  
  //  run this in background, and add only to view if artwork is selected to
  
  [self setFrame:CGRectMake(0, 0, surfaceSize.width, surfaceSize.height)];
  
  // FIXME: output debug for matSurface to check color space
#ifdef DEBUG
  cv::imwrite("/Users/steff/Desktop/matSurface.png", matSurface);
#endif
  
  /*
   */
  [imageViewSurface setFrame:CGRectMake(0, 0, surfaceSize.width, surfaceSize.height)];
  [imageViewSurface setImage:image];
}

- (void)setLocalPathArtwork:(NSString *)paramLocalPathArtwork
      refreshViewAfterwards:(BOOL) refreshViewAfterwards
{
  
  if ([urlArtwork isEqualToString:paramLocalPathArtwork])
    return;
  
  urlArtwork = paramLocalPathArtwork;
  
  if (urlArtwork == nil) {
    matArtwork.release();
    return;
  }
 
  NSLog(@"setLocalPathArtwork (%@)", urlArtwork);
  artworkSize = [RNOpenCVHelper imageSize:urlArtwork];
  
  if (artworkSize.width == 0.0 || artworkSize.height == 0.0) {
    //if (true) {
    [_eventDispatcher sendDeviceEventWithName:@"RNOpenCVEvent" body:@{
                                                                      @"type": @"error",
                                                                      @"errorCode": @"ARTWORK_IMAGE_NOT_FOUND",
                                                                      @"imageURL": urlArtwork,
                                                                      }];
    urlArtwork = nil;
    return;
  }
  
  if (artworkSize.width > 3000 || artworkSize.height > 3000) {
    //if (true) {
    [_eventDispatcher sendDeviceEventWithName:@"RNOpenCVEvent" body:@{
                                                                      @"type": @"error",
                                                                      @"errorCode": @"ARTWORK_IMAGE_TOO_BIG",
                                                                      @"imageURL": urlArtwork,
                                                                      @"width": [NSNumber numberWithFloat:artworkSize.width],
                                                                      @"height": [NSNumber numberWithFloat:artworkSize.height],
                                                                      }];
    urlArtwork = nil;
    return;
  }
  
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    cv::Mat matArtworkCreated  = [RNOpenCVHelper prepareArtwork:urlArtwork];
    dispatch_sync(dispatch_get_main_queue(), ^{
      matArtwork = matArtworkCreated.clone();
      NSDictionary *cornersArtworkParam = [propsArtwork valueForKey:@"cornersArtwork"];
      [self setCornersArtwork:cornersArtworkParam refreshViewAfterwards:NO];
      if (refreshViewAfterwards)
        [self refreshView];
    });
  });
  
#ifdef DEBUG
  //cv::imwrite("/Users/steff/Desktop/matArtwork.png", matArtwork);
#endif
}

- (void) setAlphaArtwork:(float)newAlpha {
  
  [UIView animateWithDuration:0.3f animations:^{
    [imageViewArtwork setAlpha:newAlpha];
  } completion:^(BOOL finished) {
  }];
}

- (void) setForceArtworkHidden:(BOOL)newHidden {
  
  if (newHidden == artworkHidden)
    return;
  
  artworkHidden = newHidden;
  
  float alphaTarget = 1;
  if (artworkHidden)
    alphaTarget = 0;
  
  [UIView animateWithDuration:0.5f animations:^{
    [imageViewArtwork setAlpha:alphaTarget];
  } completion:^(BOOL finished) {
  }];
}

#pragma mark - REFRESH


- (long) getTime {
  long timeMS = (long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  return timeMS;
}

- (void) sendStatusToJS:(NSString *)code
              extraData:(NSDictionary *)extraData {
  
  if (extraData == nil)
    extraData = [[NSDictionary alloc] init];
  
  long timeMS = [self getTime];
  [_eventDispatcher sendDeviceEventWithName:@"RNOpenCVEvent" body:@{
                                                                    @"type": @"status",
                                                                    @"code": code,
                                                                    @"artworkImageURL": urlArtwork,
                                                                    @"time": [NSNumber numberWithLong:timeMS],
                                                                    @"artworkWidth": [NSNumber numberWithFloat:artworkSize.width],
                                                                    @"artworkHeight": [NSNumber numberWithFloat:artworkSize.height],
                                                                    @"surfaceImageURL": urlSurface,
                                                                    @"surfaceWidth": [NSNumber numberWithFloat:surfaceSize.width],
                                                                    @"surfaceHeight": [NSNumber numberWithFloat:surfaceSize.height],
                                                                    @"extraData": extraData,
                                                                    }];
}

- (void) refreshView
{
  if (cornersArtwork == nil || urlArtwork == nil || urlSurface == nil || propsSurface == nil)
    return;
  
  if (matArtwork.rows == 0 || matArtwork.cols == 0) {
    RCTLog(@"Not doing refreshView, since not having an artwork.");
    [_eventDispatcher sendDeviceEventWithName:@"RNOpenCVEvent" body:@{
                                                                      @"type": @"error",
                                                                      @"errorCode": @"NO_ARTWORK_IMAGE",
                                                                      @"imageURL": urlArtwork,
                                                                      }];
    return;
  }
  
  [self sendStatusToJS:@"REQUEST_REFRESH_VIEW" extraData:nil];
  
  dispatch_queue_t queue = dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_async(queue, ^{
    
    // the slow stuff to be done in the background
    
    //  update homography matrix
    long startHomography = [self getTime];
    
    homography = [RNOpenCVHelper homographyFromCorners:cornersArtwork artworkSize:artworkSize];
    long diffHomography = [self getTime] - startHomography;
    NSLog(@"PROFILER: refreshHomography: %ld ms", diffHomography);
    
    //  2) warp image to final output
    long startWarp = [self getTime];
    
    if (homography.rows == 0 || homography.cols == 0) {
      [_eventDispatcher sendDeviceEventWithName:@"RNOpenCVEvent" body:@{
                                                                        @"type": @"error",
                                                                        @"errorCode": @"NO_HOMOGRAPHY_GIVEN",
                                                                        @"cornersArtwork": cornersArtwork,
                                                                        }];
      return;
    }
    
    Mat matArtworkWarped ((int)surfaceSize.height, (int)surfaceSize.width, CV_8UC4, cv::Scalar(0,0,0,0));
    warpPerspective (matArtwork, matArtworkWarped, homography, matArtworkWarped.size(), INTER_NEAREST);
    long diffWarp = [self getTime] - startWarp;
    NSLog(@"PROFILER: warpPerspective: %ld ms", diffWarp);
    
    //  3) apply hue/saturation/lightness on matArtworkRightCorners
    long startColorCorrection = [self getTime];
    
    int sHue = [[propsSurface valueForKey:@"hue"] intValue];
    int sSat = [[propsSurface valueForKey:@"saturation"] intValue];
    int sLum = [[propsSurface valueForKey:@"lightness"] intValue];
    matArtworkWarped = [RNOpenCVHelper setHueLumSat:matArtworkWarped hue:sHue lum:sLum sat:sSat];
    
    long diffColorCorrection = [self getTime] - startColorCorrection;
    NSLog(@"PROFILER: setHueLumSat: %ld ms", diffColorCorrection);
    
    long startShadow = [self getTime];
    
    Mat matSurfaceDarker;
    
    //  multiply with relative size of artwork corners to surface size
    
    float ctlx = [[cornersArtwork objectForKey:@"tlx"] floatValue];
    float ctrx = [[cornersArtwork objectForKey:@"trx"] floatValue];
    float cbrx = [[cornersArtwork objectForKey:@"brx"] floatValue];
    float cblx = [[cornersArtwork objectForKey:@"blx"] floatValue];
    float ctly = [[cornersArtwork objectForKey:@"tly"] floatValue];
    float ctry = [[cornersArtwork objectForKey:@"try"] floatValue];
    float cbry = [[cornersArtwork objectForKey:@"bry"] floatValue];
    float cbly = [[cornersArtwork objectForKey:@"bly"] floatValue];
    
    float widthCornersArtwork  = max (ctrx, cbrx) - min (ctlx, cblx);
    float heightCornersArtwork = max (cbry, cbly) - min (ctry, ctly);
    
    float widthRatio = widthCornersArtwork / surfaceSize.width;
    float heightRatio = heightCornersArtwork / surfaceSize.height;
    float minRatio = min (widthRatio, heightRatio);
    
    float shadowBlurStrength = [[propsSurface objectForKey:@"shadowBlurStrength"] floatValue] * (minRatio + 0.5);
   
    float shadowAngle = [[propsSurface objectForKey:@"shadowAngle"] floatValue] * -1;
    float shadowDistance = [[propsSurface objectForKey:@"shadowDistance"] floatValue]; // relative value from 0 - 100, 100 = surfaceSize / 10
    float shadowAlpha = [[propsSurface objectForKey:@"shadowAlpha"] floatValue] / 100.0f;
    
    shadowAngle += 90;
    float shadowAngleRad = shadowAngle / 180.0 * M_PI;
    
    float offsetX = shadowDistance * cosf(shadowAngleRad);
    float offsetY = shadowDistance * sinf(shadowAngleRad);
    
    matSurfaceDarker = [RNOpenCVHelper addShadowToSurface:matSurface
                                            artworkWarped:matArtworkWarped
                                            shadowOffsetX:offsetX
                                            shadowOffsetY:offsetY
                                              shadowAlpha:shadowAlpha
                                       shadowBlurStrength:shadowBlurStrength];
    
    long diffShadow = [self getTime] - startShadow;
    NSLog(@"PROFILER: addShadowToSurface: %ld ms", diffShadow);
    
    long startMerge = [self getTime];
    Mat surfaceCloneRGBA = matSurfaceDarker.clone();
    Mat matWall = [RNOpenCVHelper combineSurfaceAndArtwork:surfaceCloneRGBA imageArtwork:matArtworkWarped];
    long diffMerge = [self getTime] - startMerge;
    NSLog(@"PROFILER: combineSurfaceAndArtwork: %ld ms", diffMerge);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
      
      UIImage *imgWall = [RNOpenCVHelper UIImageFromCVMat:matWall];
      
      [imageViewArtwork setFrame:CGRectMake(0, 0, surfaceSize.width, surfaceSize.height)];
      [imageViewArtwork setImage:imgWall];
      
      float alphaTarget = 1;
      if (artworkHidden)
        alphaTarget = 0;
      
      [UIView animateWithDuration:0.5f animations:^{
        [imageViewArtwork setAlpha:alphaTarget];
      } completion:^(BOOL finished) {}];
      
      NSDictionary *refreshData = @{
                                    @"diffHomography": [NSNumber numberWithLong:diffHomography],
                                    @"diffWarp": [NSNumber numberWithLong:diffWarp],
                                    @"diffColorCorrection": [NSNumber numberWithLong:diffColorCorrection],
                                    @"diffShadow": [NSNumber numberWithLong:diffShadow],
                                    @"diffMerge": [NSNumber numberWithLong:diffMerge],
                                    @"propsArtwork": propsArtwork,
                                    @"propsSurface": propsSurface,
                                    };
      
      [self sendStatusToJS:@"RECEIVE_REFRESH_VIEW" extraData:refreshData];
    });
    
  });
}

@end
