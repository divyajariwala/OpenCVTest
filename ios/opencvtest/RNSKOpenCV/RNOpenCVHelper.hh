//
//  RNSKOpenCVHelper.hh
//  Created by Stephan Müller on 09/10/16.
//  Copyright © 2016 iazzu GmbH. All rights reserved.
//

#include "QuadDetectionHelper.h"

using namespace cv;

@interface RNOpenCVHelper : NSObject

- (UIImage *) testTransform:(UIImage *)image;

+ (Mat)       cvMatFromUIImage:(UIImage *)image;
+ (UIImage *) UIImageFromCVMat:(Mat)cvMat;

+ (Mat)       combineSurfaceAndArtwork:(Mat)matSurfaceRGBA
                          imageArtwork:(Mat)matArtworkRGBA;

+ (Mat)       setHueLumSat:(Mat) input
                       hue:(int) hue
                       lum:(int) lum
                       sat:(int) sat;

+ (Mat)       addShadowToSurface:(Mat)   surface
                   artworkWarped:(Mat)   artworkWarped
                   shadowOffsetX:(int)   shadowOffsetX
                   shadowOffsetY:(int)   shadowOffsetY
                     shadowAlpha:(float) shadowAlpha
              shadowBlurStrength:(float) shadowBlurStrength;

+ (UIImage *) imageFromURL:(NSString *)url;
+ (CGSize)    imageSize:(NSString *) imagePath;
+ (Mat)       blurArtwork:(Mat) artwork;
+ (Mat)       prepareArtwork:(NSString *) localPath;

+ (Mat)       homographyFromCorners:(NSDictionary *) cornersArtwork
                        artworkSize:(CGSize) artworkSize;

+ (StructRenderWallResult) renderWallNative:(NSString *)      localPathSurface
                     localPathArtworkString:(NSString *)      localPathSurfaceString
                           propsSurfaceDict:(NSDictionary *)  propsSurfaceDict
                         cornersArtworkDict:(NSDictionary *)  cornersArtworkDict
                       filenameOutputString:(NSString *)      filenameOutputString
                                jpegQuality:(int)             jpegQuality
                           pathRenderString:(NSString *)      pathRenderString
                                      debug:(BOOL)            debug;
                                      
+ (StructResizeImageResult) createResizedImageNative:(NSString *) localPathString
                                        sizeFullsize:(int)        sizeFullsize
                                filenameOutputString:(NSString *) filenameOutputString
                                    pathRenderString:(NSString *) pathRenderString
                                         jpegQuality:(int)        jpegQuality;

+ (StructDetectEdgesResult) detectEdges:(NSString *) localPathString;

+ (StructRectifyImageResult) rectifyImage:(NSString *)     localPathImage
                              cornersDict:(NSDictionary *) cornersDict
                              aspectRatio:(float)          aspectRatio
                                 contrast:(float)          contrast
                               brightness:(int)            brightness
                                sharpness:(float)          sharpness
                     filenameOutputString:(NSString *)     filenameOutputString
                      pathRectifiedString:(NSString *)     pathRectifiedString
                              jpegQuality:(int)            jpegQuality;

@end
