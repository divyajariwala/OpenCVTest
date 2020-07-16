//
//  RNSKOpenCVHelper.m
//  iazzuED
//
//  Created by Stephan Müller on 09/10/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RNOpenCVHelper.hh"
#import "UIImage+fixOrientation.h"

#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <cstring>
#include <unistd.h>
#include <chrono>

#include <sstream>
#include <algorithm>
#include <time.h>
#include <cmath>

#include "QuadDetectionHelper.h"
//#include "QuadDetectionHelper.cpp"

#include "RNOpenCVManager.hh"

using namespace cv;
using namespace std;

@implementation RNOpenCVHelper {}

+ (long) getTime {
  long timeMS = (long)([[NSDate date] timeIntervalSince1970] * 1000.0);
  return timeMS;
}

+ (Mat) prepareArtwork:(NSString *) localPath {
  
  std::string urlArtworkStd = std::string ([localPath UTF8String]);
  
  Mat matArtwork = cv::imread (urlArtworkStd, IMREAD_UNCHANGED);
  
  int channelCount = matArtwork.channels();
  NSLog(@"artwork channelCount: %d", channelCount);
  
  // blur this a bit..
  matArtwork = [RNOpenCVHelper blurArtwork:matArtwork];
  
  // set alpha channel of artwork on edges?
  int channelsArtworkOriginal = matArtwork.channels();
  NSLog(@"Amount channels artwork: %d", channelsArtworkOriginal);
  
  // MARK: avoid conversion to RGBA
  long startArtworkConvert = [self getTime];
  cv::cvtColor (matArtwork, matArtwork, CV_RGB2RGBA);
  long diffArtworkConvert = [self getTime] - startArtworkConvert;
  NSLog(@"diffArtworkConvert: %ld", diffArtworkConvert);
  
  // add some borders for edges, so they're smoother..
  
  BOOL hasAlphaChannel = channelsArtworkOriginal == 4;
  Mat matArtworkAlpha;
  if (hasAlphaChannel) {
    vector <Mat> matArtworkChannels2;
    split(matArtwork, matArtworkChannels2);
    matArtworkAlpha = matArtworkChannels2[3];
  }
  else {
    matArtworkAlpha = Mat (matArtwork.size(), CV_8UC1, Scalar(255));
  }
  
  NSLog(@"type of matArtworkAlpha: %d", matArtworkAlpha.type());
#ifdef DEBUG
  cv::imwrite ("~/Desktop/matArtworkAlpha.png", matArtworkAlpha);
#endif
  
  Mat matArtworkInsets = Mat (matArtwork.size(), CV_8UC1, Scalar(255));
  int cornerInsetPX = 3; // x pixels on edges MUST be black -> white
  for (int insetPX = 0; insetPX < cornerInsetPX; insetPX++) {
    
    // insetPX = 0, addValue = 255
    // insetPX = 1, addValue = 255 * (9/10) = 229
    // insetPX = 2, addValue = 255 * (8/10) = 204
    // ...
    int addValue = 255.0 * (((float)cornerInsetPX - (float)insetPX) / (float)cornerInsetPX);
    
    int xLeft = insetPX;
    int xRight = matArtworkAlpha.cols - insetPX - 1;
    for (int y = insetPX; y < matArtworkAlpha.rows - insetPX; y++) {
      int newVal = MAX(0, 255 - addValue);
      matArtworkInsets.at<char>(y, xLeft) = newVal;
      matArtworkInsets.at<char>(y, xRight) = newVal;
    }
    
    int yTop = insetPX;
    int yBottom = matArtworkAlpha.rows - insetPX - 1;
    for (int x = insetPX; x < matArtworkAlpha.cols - insetPX; x++) {
      int newVal = MAX(0, 255 - addValue);
      matArtworkInsets.at<char>(yTop, x) = newVal;
      matArtworkInsets.at<char>(yBottom, x) = newVal;
    }
  }
  
  Mat alphaMaskNew = Mat (matArtwork.size(), CV_8UC1);
  
  //  now, MULTIPY matArtworkInsets over matArtworkAlpha
  for (int y = 0; y < matArtwork.rows; y++)
    for (int x = 0; x < matArtwork.cols; x++) {
      unsigned char valArtworkOpacity = matArtworkAlpha.at<unsigned char>(y,x);
      unsigned char valInsetOpacity   = matArtworkInsets.at<unsigned char>(y,x);
      
      int artworkOpacity = (int)valArtworkOpacity;
      int insetOpacity = (int)valInsetOpacity;
      float transparencyFactor = ((float)insetOpacity / 255.0);
      
      int opacityNew = (float)artworkOpacity * transparencyFactor;
      
      int valArtworkOpacityNew = MAX(0, MIN(255, opacityNew));
      char opaNew = (char)valArtworkOpacityNew;
      
      alphaMaskNew.at<char>(y, x) = opaNew;
    }
  
  //  now, split matArtwork (original) and add 4th channel as alpha
  
  vector <Mat> matArtworkChannelsRGBA;
  split(matArtwork, matArtworkChannelsRGBA);
  
  vector <Mat> matArtworkChannelsFinal;
  matArtworkChannelsFinal.push_back (matArtworkChannelsRGBA[0]);
  matArtworkChannelsFinal.push_back (matArtworkChannelsRGBA[1]);
  matArtworkChannelsFinal.push_back (matArtworkChannelsRGBA[2]);
  matArtworkChannelsFinal.push_back (alphaMaskNew);
  
  //cv::imwrite("/Users/steff/Desktop/alphaMaskNew.png", alphaMaskNew);
  Mat matArtworkFinal;
  merge(matArtworkChannelsFinal, matArtworkFinal);
  //cv::imwrite("/Users/steff/Desktop/matArtworkFinal.png", matArtworkFinal);
  
  return matArtworkFinal;
}

+ (cv::Mat) homographyFromCorners:(NSDictionary *) cornersArtwork
          artworkSize:(CGSize)artworkSize
{ // TODO: Change to
  
  Point2f tlAbs = Point2f ([[cornersArtwork objectForKey:@"tlx"] floatValue], [[cornersArtwork objectForKey:@"tly"] floatValue]);
  Point2f trAbs = Point2f ([[cornersArtwork objectForKey:@"trx"] floatValue], [[cornersArtwork objectForKey:@"try"] floatValue]);
  Point2f brAbs = Point2f ([[cornersArtwork objectForKey:@"brx"] floatValue], [[cornersArtwork objectForKey:@"bry"] floatValue]);
  Point2f blAbs = Point2f ([[cornersArtwork objectForKey:@"blx"] floatValue], [[cornersArtwork objectForKey:@"bly"] floatValue]);
  
  Point2f pts_dst[4];
  pts_dst[0] = tlAbs;
  pts_dst[1] = trAbs;
  pts_dst[2] = brAbs;
  pts_dst[3] = blAbs;
  
  Point2f pts_src[4];
  pts_src[0] = Point2f(0, 0);
  pts_src[1] = Point2f(artworkSize.width-0, 0);
  pts_src[2] = Point2f(artworkSize.width-0, artworkSize.height-0);
  pts_src[3] = Point2f(0, artworkSize.height-0);
  
  vector<Point2f> pts_dst_v;
  pts_dst_v.push_back(tlAbs);
  pts_dst_v.push_back(trAbs);
  pts_dst_v.push_back(brAbs);
  pts_dst_v.push_back(blAbs);
  
  vector<Point2f> pts_src_v;
  pts_src_v.push_back(pts_src[0]);
  pts_src_v.push_back(pts_src[1]);
  pts_src_v.push_back(pts_src[2]);
  pts_src_v.push_back(pts_src[3]);
  
  Mat homography = cv::findHomography (pts_src_v, pts_dst_v);
  return homography;
}

Mat sharpen2 (const Mat& img) {
  
  // sharpen image using "unsharp mask" algorithm
  
  Mat blurred;
  double sigma = 1, threshold = 5, amount = 10;
  
  GaussianBlur(img, blurred, cv::Size(), sigma, sigma);
  Mat lowConstrastMask = abs(img - blurred) < threshold;
  
  Mat sharpened = img*(1+amount) + blurred*(-amount);
  img.copyTo (sharpened, lowConstrastMask);
  
  return sharpened;
}

void sharpen (const Mat& img, Mat& result)
{
  result.create(img.size(), img.type());
  //Processing the inner edge of the pixel point, the image of the outer edge of the pixel should be additional processing
  for (int row = 1; row < img.rows-1; row++)
  {
    //Front row pixel
    const uchar* previous = img.ptr<const uchar>(row-1);
    //Current line to be processed
    const uchar* current = img.ptr<const uchar>(row);
    //new row
    const uchar* next = img.ptr<const uchar>(row+1);
    uchar *output = result.ptr<uchar>(row);
    int ch = img.channels();
    int starts = ch;
    int ends = (img.cols - 1) * ch;
    for (int col = starts; col < ends; col++)
    {
      //The traversing pointer of the output image is synchronized with the current row, and each channel value of each pixel in each row is given a increment, because the channel number of the image is to be taken into account.
      *output++ = saturate_cast<uchar>(5 * current[col] - current[col-ch] - current[col+ch] - previous[col] - next[col]);
    }
  } //end loop
  //Processing boundary, the peripheral pixel is set to 0
  result.row(0).setTo(Scalar::all(0));
  result.row(result.rows-1).setTo(Scalar::all(0));
  result.col(0).setTo(Scalar::all(0));
  result.col(result.cols-1).setTo(Scalar::all(0));
}

- (Mat) addGradient:(const Mat&) img
     gradientRadius:(float) gradientRadius
      gradientPower:(float) gradientPower {
  
  Mat maskImg(img.size(), CV_64F);
  
  //  Mat, radius, power
  //generateGradient(maskImg, 1.0, 0.8);
  generateGradient(maskImg, gradientRadius, gradientPower);
  
  //  save mask (dummy)
  
  cv::Mat gradient;
  cv::normalize(maskImg, gradient, 0, 255, CV_MINMAX);
  
  NSString *maskOutput = [[RNOpenCVManager getOpenCVDirectory] stringByAppendingPathComponent:@"gradient.png"];
  //cv::imwrite([maskOutput UTF8String], gradient);
  
  Mat labImg(img.size(), CV_8UC3);
  cvtColor(img, labImg, CV_BGR2Lab);
  
  for (int row = 0; row < labImg.size().height; row++)
  {
    for (int col = 0; col < labImg.size().width; col++)
    {
      cv::Vec3b value = labImg.at<cv::Vec3b>(row, col);
      value.val[0] *= maskImg.at<double>(row, col);
      labImg.at<cv::Vec3b>(row, col) =  value;
    }
  }
  
  Mat output;
  cvtColor (labImg, output, CV_Lab2BGR);
  //cvtColor (labImg, output, CV_Lab2RGB);
  
  return output;
}

+ (cv::Mat) combineSurfaceAndArtwork:(cv::Mat)matSurfaceRGBA
                    imageArtwork:(cv::Mat)matArtworkRGBA {
  
  cv::Point location = cv::Point (0, 0);
  Mat newMat = matSurfaceRGBA.clone();
  overlayImage (&newMat, &matArtworkRGBA, location);
  return newMat;
}

+ (Mat) blurArtwork:(Mat)matArtwork {
  
  vector <Mat> matArtworkChannels;
  split(matArtwork, matArtworkChannels);
  
  int artworkBlurFactor = MAX((float)matArtwork.cols, (float)matArtwork.rows) / 500.0;
  artworkBlurFactor = artworkBlurFactor * 2 + 1;
  
  NSLog(@"artworkBlurFactor: %d", artworkBlurFactor);
  
  vector <Mat> matArtworkChannelsBlurred;
  for (int i = 0; i < matArtworkChannels.size(); i++) {
    Mat channel = matArtworkChannels[i];
    Mat channelBlurred = channel.clone();
    GaussianBlur (channel, channelBlurred, cv::Size (artworkBlurFactor, artworkBlurFactor), 0, 0);
    matArtworkChannelsBlurred.push_back(channelBlurred);
  }
  Mat matArtworkBlurred;
  merge(matArtworkChannelsBlurred, matArtworkBlurred);
  
  return matArtworkBlurred;
}

- (UIImage *) testTransform:(UIImage *)image {
  
  int threshold_value = 10;
  int const max_BINARY_value = 2147483647;
  
  Mat src=[RNOpenCVHelper cvMatFromUIImage:image];
  
  Mat src_gray=[RNOpenCVHelper cvMatFromUIImage:image];
  cvtColor(src, src_gray, COLOR_RGB2GRAY);
  
  Mat srcEqualized = src_gray.clone();
  equalizeHist (src_gray, srcEqualized);
  
  Mat matClahe = src.clone();
  matClahe = getCLAHE(src, 1.5);
  
  Mat matSaturated = shiftHueLumSat(matClahe, 0, 0, 0);
  //matSharp = sharpen2(matSaturated);
  
  Mat matVignette = matSaturated.clone();
  matVignette = [self addGradient:matSaturated gradientRadius:0.5 gradientPower:0.2];
  
  return [RNOpenCVHelper UIImageFromCVMat:matVignette];
  
  //return [self UIImageFromCVMat:srcEqualized];
  
  /*
  //  1) create CV Material from UIImage
  cv::Mat src_gray=[self cvMatFromUIImage:image];
  
  
  //  create destination based on
  Mat dst;
  dst=src_gray;
  
  cv::cvtColor(src_gray, dst, cv::COLOR_RGB2GRAY);
  //cv::Mat canny_output;
  std::vector<std::vector<cv::Point> > contours;
  std::vector<cv::Vec4i> hierarchy;
  
  cv::RNG rng(12345);
  
  cv::threshold( dst, dst, threshold_value, max_BINARY_value,cv::THRESH_OTSU );
  
  cv::Mat contourOutput = dst.clone();
  cv::findContours( contourOutput, contours, cv::RETR_LIST, cv::CHAIN_APPROX_NONE );
  
  //Draw the contours
  cv::Mat contourImage(dst.size(), CV_8UC3, cv::Scalar(0,0,0));
  cv::Scalar colors[3];
  colors[0] = cv::Scalar(255, 0, 0);
  colors[1] = cv::Scalar(0, 255, 0);
  colors[2] = cv::Scalar(0, 0, 255);
  for (size_t idx = 0; idx < contours.size(); idx++) {
    cv::drawContours(contourImage, contours, idx, colors[idx % 3], 50);
  }
  
  return [self UIImageFromCVMat:contourOutput];
   */
}

+ (UIImage *)imageFromURL:(NSString *)url {
  NSURL     *imageURL   = [NSURL URLWithString:url];
  NSString  *path       = [imageURL path];
  NSData    *imageData  = [[NSFileManager defaultManager] contentsAtPath:path];
  UIImage   *imageRaw   = [UIImage imageWithData:imageData];
  UIImage   *image      = [imageRaw fixOrientation];
  return image;
}

+ (CGSize) imageSize:(NSString *)imagePath {
  UIImage   *image = [self imageFromURL:imagePath];
  CGSize imageSize = CGSizeMake(image.size.width, image.size.height);
  return imageSize;
}

+ (Mat) addShadowToSurface:(Mat)surface
             artworkWarped:(Mat)artworkWarped
             shadowOffsetX:(int)shadowOffsetX
             shadowOffsetY:(int)shadowOffsetY
               shadowAlpha:(float)shadowAlpha
        shadowBlurStrength:(float)shadowBlurStrength
{
  const char *pathRenderDummy = [[NSString stringWithString:@""] UTF8String];
  return addShadowToSurface (surface, artworkWarped, shadowOffsetX, shadowOffsetY, shadowAlpha, shadowBlurStrength, pathRenderDummy, false);
}

+ (cv::Mat)setHueLumSat:(cv::Mat) input  hue:(int)hue lum:(int)lum sat:(int)sat {
   
  return shiftHueLumSat(input, hue, lum, sat);
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
  CGColorSpaceRef colorSpace = CGImageGetColorSpace (image.CGImage);
  CGFloat cols = image.size.width;
  CGFloat rows = image.size.height;
  
  cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
  
  CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                  cols,                       // Width of bitmap
                                                  rows,                       // Height of bitmap
                                                  8,                          // Bits per component
                                                  cvMat.step[0],              // Bytes per row
                                                  colorSpace,                 // Colorspace
                                                  kCGImageAlphaNoneSkipLast |
                                                  kCGBitmapByteOrderDefault); // Bitmap info flags
  
  CGContextDrawImage (contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
  CGContextRelease (contextRef);
  
  return cvMat;
}
- (Mat)cvMatGrayFromUIImage:(UIImage *)image
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

+ (StructPropsSurface) make_native_props_surface:(NSDictionary *) propsSurfaceDict {

  StructPropsSurface propsSurface;
  propsSurface.hue                = [[propsSurfaceDict objectForKey:@"hue"]         intValue];
  propsSurface.saturation         = [[propsSurfaceDict objectForKey:@"saturation"]  intValue];
  propsSurface.lightness          = [[propsSurfaceDict objectForKey:@"lightness"]   intValue];
  propsSurface.shadowAngle        = [[propsSurfaceDict objectForKey:@"shadowAngle"]         doubleValue];
  propsSurface.shadowDistance     = [[propsSurfaceDict objectForKey:@"shadowDistance"]      doubleValue];
  propsSurface.shadowAlpha        = [[propsSurfaceDict objectForKey:@"shadowAlpha"]         doubleValue];
  propsSurface.shadowBlurStrength = [[propsSurfaceDict objectForKey:@"shadowBlurStrength"]  doubleValue];
  return propsSurface;
}

+ (StructCornersArtwork) make_native_corners_artwork:(NSDictionary *) cornersArtworkDict {
  
  StructCornersArtwork cornersArtworkStruct;
  cornersArtworkStruct.ptlx = [[cornersArtworkDict objectForKey:@"tlx"] floatValue];
  cornersArtworkStruct.ptly = [[cornersArtworkDict objectForKey:@"tly"] floatValue];
  cornersArtworkStruct.ptrx = [[cornersArtworkDict objectForKey:@"trx"] floatValue];
  cornersArtworkStruct.ptry = [[cornersArtworkDict objectForKey:@"try"] floatValue];
  cornersArtworkStruct.pbrx = [[cornersArtworkDict objectForKey:@"brx"] floatValue];
  cornersArtworkStruct.pbry = [[cornersArtworkDict objectForKey:@"bry"] floatValue];
  cornersArtworkStruct.pblx = [[cornersArtworkDict objectForKey:@"blx"] floatValue];
  cornersArtworkStruct.pbly = [[cornersArtworkDict objectForKey:@"bly"] floatValue];
  return cornersArtworkStruct;
}

+ (StructRenderWallResult) renderWallNative:(NSString *)     localPathSurfaceString
                     localPathArtworkString:(NSString *)     localPathArtworkString
                           propsSurfaceDict:(NSDictionary *) propsSurfaceDict
                         cornersArtworkDict:(NSDictionary *) cornersArtworkDict
                       filenameOutputString:(NSString *)     filenameOutputString
                                jpegQuality:(int)            jpegQuality
                           pathRenderString:(NSString *)     pathRenderString
                                      debug:(BOOL)           debug {

  StructRenderWallResult renderWallResult;
  renderWallResult.success = false;
  renderWallResult.width   = 0;
  renderWallResult.height  = 0;

  const char *localPathSurface  = [localPathSurfaceString UTF8String];
  const char *localPathArtwork  = [localPathArtworkString UTF8String];
  const char *filenameOutput    = [filenameOutputString UTF8String];
  const char *pathRender        = [pathRenderString UTF8String];
  
  vector<int> compression_params;
  compression_params.push_back (CV_IMWRITE_JPEG_QUALITY);
  compression_params.push_back (jpegQuality);

  StructPropsSurface   propsSurface   = [RNOpenCVHelper make_native_props_surface:  propsSurfaceDict];
  StructCornersArtwork cornersArtwork = [RNOpenCVHelper make_native_corners_artwork:cornersArtworkDict];
  
  //  SURFACE --> matSurface
  cv::Point surfaceSize = getImageSizeByLocalPath (localPathSurface);
  if ((surfaceSize.x == 0) || (surfaceSize.y == 0)) {
    [NSException raise:@"SURFACE_IMAGE_NOT_FOUND" format:@"SURFACE_IMAGE_NOT_FOUND"];
  }
  //  different in Android, because of possible iOS rotation meta data that needs to be fixed first
  UIImage *imageSurface = [RNOpenCVHelper imageFromURL:localPathSurfaceString];
  cv::Mat matSurface    = [RNOpenCVHelper cvMatFromUIImage:imageSurface]; // because of fixOrientation
  cv::cvtColor (matSurface, matSurface, CV_BGRA2RGB); // only on iOS!
  if (debug) {
    char filepathSurface[300]; sprintf (filepathSurface, "%s/02a_matSurface.jpg", pathRender);
    cv::imwrite (filepathSurface, matSurface, compression_params);
  }

#ifdef DEBUG
  cv::imwrite ("/Users/steff/Desktop/matSurface1Original.png", matSurface);
#endif

  //  ARTWORK --> matArtwork
  cv::Point artworkSize = getImageSizeByLocalPath (localPathArtwork);
  if ((artworkSize.x == 0) || (artworkSize.y == 0)) {
    [NSException raise:@"ARTWORK_IMAGE_NOT_FOUND" format:@"ARTWORK_IMAGE_NOT_FOUND"];
  }
  else if ((artworkSize.x > RENDER_IMAGE_SIZE_MAX) || (artworkSize.y > RENDER_IMAGE_SIZE_MAX)) {
    [NSException raise:@"ARTWORK_IMAGE_TOO_BIG" format:@"ARTWORK_IMAGE_TOO_BIG"];
  }

  cv::Mat matArtwork = prepareArtwork (localPathArtwork, pathRender, debug);
  if (debug) {
    char filepathArtwork[300]; sprintf (filepathArtwork, "%s/01a_matArtwork.png", pathRender);
    cv::imwrite (filepathArtwork, matArtwork/*, compression_params*/);
  }

#ifdef DEBUG
  cv::imwrite ("/Users/steff/Desktop/matArtwork.png", matArtwork);
#endif

  
  //  WARP --> matArtworkWarped
  cv::Mat homography = homographyFromCorners (cornersArtwork, artworkSize.x, artworkSize.y);
  if (homography.rows == 0 || homography.cols == 0) {
    [NSException raise:@"NO_HOMOGRAPHY_GIVEN" format:@"NO_HOMOGRAPHY_GIVEN"];
  }
  cv::Mat matArtworkWarped (matSurface.rows, matSurface.cols, CV_8UC4, cv::Scalar (0,0,0,0));
  cv::warpPerspective (matArtwork, matArtworkWarped, homography, matArtworkWarped.size(), INTER_NEAREST);
  if (debug) {
    char filepathArtworkWarped[300]; sprintf (filepathArtworkWarped, "%s/01b_matArtworkWarped.png", pathRender);
    cv::imwrite (filepathArtworkWarped, matArtworkWarped);
  }
  
#ifdef DEBUG
  cv::imwrite ("/Users/steff/Desktop/matArtworkWarped1Warped.png", matArtworkWarped);
#endif
  
  //  WARP'S COLOR CORRECTION --> matArtworkWarped
  matArtworkWarped = setHueLumSat (matArtworkWarped, propsSurface.hue, propsSurface.lightness, propsSurface.saturation);
  if (matArtworkWarped.rows == 0 || matArtworkWarped.cols == 0) {
    [NSException raise:@"HUE_LUM_SAT_ERROR" format:@"HUE_LUM_SAT_ERROR"];
  }
  if (debug) {
    char filepathArtworkWarpedCC[300]; sprintf (filepathArtworkWarpedCC, "%s/01c_matArtworkWarpedCC.png", pathRender);
    cv::imwrite (filepathArtworkWarpedCC, matArtworkWarped);
  }

#ifdef DEBUG
  cv::imwrite ("/Users/steff/Desktop/matArtworkWarped2CC.png", matArtworkWarped);
#endif
  
  //  SHADOW --> matSurfaceDarker
  float shadowAlpha = propsSurface.shadowAlpha / 100.0f;
  float shadowBlurStrength = propsSurface.shadowBlurStrength;
  float shadowDistance = propsSurface.shadowDistance;
  float shadowAngle = propsSurface.shadowAngle * -1.0 + 90.0;
  float shadowAngleRad = shadowAngle / 180.0 * M_PI;
  float offsetX = shadowDistance * cosf (shadowAngleRad);
  float offsetY = shadowDistance * sinf (shadowAngleRad);
  cv::Mat matSurfaceDarker = addShadowToSurface (matSurface, matArtworkWarped, (int)offsetX, (int)offsetY, shadowAlpha, shadowBlurStrength, pathRender, debug);
  if (matSurfaceDarker.rows == 0 || matSurfaceDarker.cols == 0) {
    [NSException raise:@"ADD_SHADOW_ERROR" format:@"ADD_SHADOW_ERROR"];
  }
  if (debug) {
    char filepathMatSurfaceDarker[300]; sprintf (filepathMatSurfaceDarker, "%s/02b_matSurfaceDarker.jpg", pathRender);
    cv::imwrite (filepathMatSurfaceDarker, matSurfaceDarker, compression_params);
  }
  
#ifdef DEBUG
  cv::imwrite ("/Users/steff/Desktop/matSurface2Darker.png", matSurfaceDarker);
#endif

  //  OVERLAY IMAGES --> matWall
  cv::Mat surfaceCloneRGBA = matSurfaceDarker.clone();
  cv::Mat matWall = combineSurfaceAndArtwork (surfaceCloneRGBA, matArtworkWarped);

#ifdef DEBUG
  cv::imwrite ("/Users/steff/Desktop/matWall.png", matWall);
#endif
  
  bool writeResult = true; // optimistic approach
  char filenameWall[300]; sprintf (filenameWall, "%s/%s", pathRender, filenameOutput);
  try {
    writeResult = cv::imwrite (filenameWall, matWall, compression_params);
  }
  
  catch (runtime_error& ex) {
    [NSException raise:@"WRITE_RENDERED_IMAGE_EXCEPTION" format:@"WRITE_RENDERED_IMAGE_EXCEPTION"];
  }
  if (!writeResult) {
    [NSException raise:@"WRITE_RENDERED_IMAGE_ERROR" format:@"WRITE_RENDERED_IMAGE_ERROR"];
  }

  /*
  if (debug) {
    cv::Mat writtenImage = cv::imread (filenameWall, IMREAD_UNCHANGED);
    if ((writtenImage.cols == 0) || (writtenImage.rows == 0)) {
      [NSException raise:@"WRITE_RENDERED_IMAGE_READ_ERROR" format:@"WRITE_RENDERED_IMAGE_READ_ERROR"];
    }
  }
  */

  //  RESULT

  // StructRenderWallResult emptyResult;
  // return emptyResult;

  renderWallResult.success = true;
  renderWallResult.width   = matSurface.cols;
  renderWallResult.height  = matSurface.rows;
  
  //[NSException raise:@"WRITE_RENDERED_IMAGE_ERROR" format:@"WRITE_RENDERED_IMAGE_ERROR"];
  matSurface.release ();
  matArtwork.release ();
  homography.release ();
  matArtworkWarped.release ();
  matSurfaceDarker.release ();
  surfaceCloneRGBA.release ();
  matWall.release ();
  
  return renderWallResult;
}

+ (StructResizeImageResult) createResizedImageNative:(NSString *) localPathString
                                        sizeFullsize:(int)        sizeFullsize
                                filenameOutputString:(NSString *) filenameOutputString
                                    pathRenderString:(NSString *) pathRenderString
                                         jpegQuality:(int)        jpegQuality {

  StructResizeImageResult resizeImageResult;

  const char *localPath       = [localPathString UTF8String];
  const char *filenameOutput  = [filenameOutputString UTF8String];
  const char *pathRender      = [pathRenderString UTF8String];

  cv::Point materialSize = getImageSizeByLocalPath (localPath);
  if ((materialSize.x == 0) || (materialSize.y == 0)) {
    [NSException raise:@"SURFACE_IMAGE_NOT_FOUND" format:@"SURFACE_IMAGE_NOT_FOUND"];
  }
  //  different in Android, because of possible iOS rotation meta data that needs to be fixed first
  UIImage *image = [RNOpenCVHelper imageFromURL:localPathString]; // use Objective-C string here
  cv::Mat mat    = [RNOpenCVHelper cvMatFromUIImage:image]; // because of fixOrientation
  cv::cvtColor (mat, mat, CV_BGRA2RGB); // only on iOS!

  int srcWidth  = materialSize.x;
  int srcHeight = materialSize.y;
  
  double resizeFactor = getResizeFactor (srcWidth, srcHeight, sizeFullsize);
  
  int newWidth  = round (resizeFactor * (float) srcWidth);
  int newHeight = round (resizeFactor * (float) srcHeight);

  Mat matResized = resizeMat (mat, newWidth, newHeight);

  bool writeResult = true; // optimistic approach
  char filenameMatResized[300]; sprintf (filenameMatResized, "%s/%s", pathRender, filenameOutput);
  try {
    vector<int> compression_params;
    compression_params.push_back (CV_IMWRITE_JPEG_QUALITY);
    compression_params.push_back (jpegQuality);
    writeResult = cv::imwrite (filenameMatResized, matResized, compression_params);
  }
  catch (runtime_error& ex) {
    [NSException raise:@"WRITE_RENDERED_IMAGE_EXCEPTION" format:@"WRITE_RENDERED_IMAGE_EXCEPTION"];
  }
  if (!writeResult) {
    [NSException raise:@"WRITE_RENDERED_IMAGE_ERROR" format:@"WRITE_RENDERED_IMAGE_ERROR"];
  }

  resizeImageResult.success = true;
  resizeImageResult.width   = newWidth;
  resizeImageResult.height  = newHeight;

  return resizeImageResult;
}

+ (StructDetectEdgesResult) detectEdges:(NSString *) localPathString {

  StructDetectEdgesResult detectEdgesResult;
  const char *localPath = [localPathString UTF8String];

  // [NSException raise:@"IMAGE_NOT_FOUND" format:@"IMAGE_NOT_FOUND"]; // for debugging

  //Mat srcOriginal = [RNOpenCVManager cvMatFromUIImage:imageSrc];
  Mat srcOriginal = cv::imread (localPath, IMREAD_UNCHANGED);
  // NSString *pathSrc = [[NSURL URLWithString:localPathString] path];
  // UIImage *imageSrc = [[UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:pathSrc]] fixOrientation];
  
  int srcWidth  = srcOriginal.cols;
  int srcHeight = srcOriginal.rows;
  if (srcWidth == 0 || srcHeight == 0) {
    [NSException raise:@"IMAGE_NOT_FOUND" format:@"IMAGE_NOT_FOUND"]; // for debugging
  }

  /*
  NSDictionary *areaOfInterest = [options valueForKey:@"areaOfInterest"];
  float aoiX0 = [[areaOfInterest valueForKey:@"x0"] floatValue];
  float aoiY0 = [[areaOfInterest valueForKey:@"y0"] floatValue];
  float aoiX1 = [[areaOfInterest valueForKey:@"x1"] floatValue];
  float aoiY1 = [[areaOfInterest valueForKey:@"y1"] floatValue];
  if (aoiX1 == 0) aoiX1 = 1.0;
  if (aoiY1 == 0) aoiY1 = 1.0;
  
  NSDictionary *pointUserTouch = [options valueForKey:@"pointUserTouch"];
  float userTouchX = [[pointUserTouch valueForKey:@"x"] floatValue];
  float userTouchY = [[pointUserTouch valueForKey:@"y"] floatValue];
  if (userTouchX == 0) userTouchX = 0.5;
  if (userTouchY == 0) userTouchY = 0.5;
  
  vector <Vec4f> extraHoughLinesRel;
  NSArray *extraHoughLinesParam = [options valueForKey:@"extraHoughLines"];
  */
  
  //NSDictionary *areaOfInterest = [NSDictionary init];

  float aoiX0 = 0.0;
  float aoiY0 = 0.0;
  float aoiX1 = 1.0;
  float aoiY1 = 1.0;
  
  float userTouchX = 0.5;
  float userTouchY = 0.5;
  
  vector <Vec4f> extraHoughLinesRel; // empty vector

  /*
  NSArray *extraHoughLinesParam = [NSArray init];
  if (extraHoughLinesParam != nil) {
    NSUInteger count = [extraHoughLinesParam count];
    for (NSUInteger index = 0; index < count ; index++) {
      NSDictionary *extraLine = (NSDictionary *) extraHoughLinesParam[index];
      Vec4f extraLineV;
      extraLineV[0] = [[extraLine objectForKey:@"x0"] floatValue];
      extraLineV[1] = [[extraLine objectForKey:@"y0"] floatValue];
      extraLineV[2] = [[extraLine objectForKey:@"x1"] floatValue];
      extraLineV[3] = [[extraLine objectForKey:@"y1"] floatValue];
      extraHoughLinesRel.push_back (extraLineV);
    }
  }
  */
  
  int sizeDetect = 750;
  
  double resizeFactor = getResizeFactor (srcWidth, srcHeight, sizeDetect);
  
  int newWidth  = round (resizeFactor * (float) srcWidth);
  int newHeight = round (resizeFactor * (float) srcHeight);
  
  Mat srcColor = resizeMat (srcOriginal, newWidth, newHeight);

  //NSDictionary* createResizedJPEGResult = [RNOpenCVManager createResizedJPEG:localPath sizeFullsize:sizeDetect quality:1.0];
  //double resizeFactor = getResizeFactor (srcWidth, srcHeight, sizeDetect);
  /*
  NSString *urlResizedLocal = [createResizedJPEGResult objectForKey:@"resizedURL"];
  NSString *path = [[NSURL URLWithString:urlResizedLocal] path];
  UIImage *image = [[UIImage imageWithData:[[NSFileManager defaultManager] contentsAtPath:path]] fixOrientation];
  int imageWidth = image.size.width;
  Mat srcColor = [RNOpenCVManager cvMatFromUIImage:image];
  */

  Mat srcConvertedBW;
  cvtColor(srcColor, srcConvertedBW, cv::COLOR_RGBA2GRAY);
  
  //NSString *filenameNoExt = [createResizedJPEGResult objectForKey:@"srcFilenameNoExt"];
  NSString *filenameNoExt = [NSString stringWithFormat:@"EdgeDetection"]; // for debugging only
  
  //  measureLine
  int measureLineLengthMM = 35;
  
  Vec4f measureLine = Vec4f (214.0 / (float)srcWidth, 1676.0 / (float)srcHeight, 365.0 / (float)srcWidth, 1605.0 / (float)srcHeight);
  
  EdgeDetectionResult res = detectEdges (srcOriginal, srcConvertedBW, resizeFactor, userTouchX, userTouchY, aoiX0, aoiY0, aoiX1, aoiY1, extraHoughLinesRel, measureLineLengthMM, measureLine, nil, (char*)[filenameNoExt UTF8String] );
  
  if (res.error == false) { // everything went okay!
    /*
    NSMutableArray *linesImage = [[NSMutableArray alloc] init];
    for (int i = 0; i < res.linesImage.size(); i++) {
      Vec4f rli = res.linesImage[i];
      NSMutableDictionary *lineImage = @{
                                         @"x0": [NSNumber numberWithFloat:rli[0]],
                                         @"y0": [NSNumber numberWithFloat:rli[1]],
                                         @"x1": [NSNumber numberWithFloat:rli[2]],
                                         @"y1": [NSNumber numberWithFloat:rli[3]],
                                         };
      [linesImage addObject:lineImage];
    }
    */

    detectEdgesResult.ctlx = res.tl.x;
    detectEdgesResult.ctly = res.tl.y;
    detectEdgesResult.ctrx = res.tr.x;
    detectEdgesResult.ctry = res.tr.y;
    detectEdgesResult.cbrx = res.br.x;
    detectEdgesResult.cbry = res.br.y;
    detectEdgesResult.cblx = res.bl.x;
    detectEdgesResult.cbly = res.bl.y;
    detectEdgesResult.vphx = res.vph.x;
    detectEdgesResult.vphy = res.vph.y;
    detectEdgesResult.vpvx = res.vpv.x;
    detectEdgesResult.vpvy = res.vpv.y;

    return detectEdgesResult;
  }
  else {
    [NSException raise:@"ERROR_DETECTING_EDGES" format:@"ERROR_DETECTING_EDGES"]; // for debugging
  }
  return detectEdgesResult;
}

+ (StructRectifyImageResult) rectifyImage:(NSString *)     localPathImage
                              cornersDict:(NSDictionary *) cornersDict
                              aspectRatio:(float)          aspectRatio
                                 contrast:(float)          contrast
                               brightness:(int)            brightness
                                sharpness:(float)          sharpness
                     filenameOutputString:(NSString *)     filenameOutputString
                      pathRectifiedString:(NSString *)     pathRectifiedString
                              jpegQuality:(int)            jpegQuality {
  
  //  Part 1: Prepare variables for C++
  const char *filenameOutput   = [filenameOutputString UTF8String];
  const char *pathRectified    = [pathRectifiedString UTF8String];
  const char *localPath        = [localPathImage UTF8String];
  StructCornersArtwork corners = [RNOpenCVHelper make_native_corners_artwork:cornersDict]; // different in Android

  //  Part 2: Create OpenCV Material - if possible
  cv::Point materialSize     = getImageSizeByLocalPath (localPath);
  int srcWidth  = materialSize.x;
  int srcHeight = materialSize.y;
  if (srcWidth == 0 || srcHeight == 0) {
    [NSException raise:@"IMAGE_NOT_FOUND" format:@"IMAGE_NOT_FOUND"];
  }
  UIImage *image = [RNOpenCVHelper imageFromURL:localPathImage]; // use Objective-C string here
  cv::Mat mat    = [RNOpenCVHelper cvMatFromUIImage:image]; // because of fixOrientation
  cv::cvtColor (mat, mat, CV_BGRA2RGB); // only on iOS!
  
  //  Part 3: Create output image
  int outputWidth  = 1500; // maximum width in pixels
  int outputHeight = (int)((double)outputWidth / (aspectRatio));
  cv::Mat matRectifiedImage = rectifyImage (mat, corners, outputWidth, outputHeight, filenameOutput, pathRectified, jpegQuality);
  
  //  Part 4: Apply Contrast & Brightness
  cv::Mat matBrightnessContrast = cv::Mat::zeros (matRectifiedImage.size(), matRectifiedImage.type());
  for (int y = 0; y < matRectifiedImage.rows; y++) {
    for (int x = 0; x < matRectifiedImage.cols; x++) {
      for (int c = 0; c < 3; c++) {
        matBrightnessContrast.at<Vec3b>(y,x)[c] = saturate_cast<uchar>(contrast*(matRectifiedImage.at<Vec3b>(y,x)[c]) + brightness);
      }
    }
  }
  matRectifiedImage = matBrightnessContrast;
  
  //  Part 5: Sharpen
  cv::Mat gaussBlur;
  cv::GaussianBlur(matRectifiedImage, gaussBlur, cv::Size(0,0), 3);
  cv::addWeighted (matRectifiedImage, 1.0 + sharpness, gaussBlur, sharpness * -1.0, 0, matRectifiedImage);
  
  //  Part 6: Save output image
  bool writeResult = true; // optimistic approach
  char filenameImage[300]; sprintf (filenameImage, "%s/%s", pathRectified, filenameOutput);
  try {
    vector<int> compression_params;
    compression_params.push_back (CV_IMWRITE_JPEG_QUALITY);
    compression_params.push_back (jpegQuality);
    writeResult = cv::imwrite (filenameImage, matRectifiedImage, compression_params);
  }
  catch (runtime_error& ex) {
    [NSException raise:@"WRITE_IMAGE_EXCEPTION" format:@"WRITE_IMAGE_EXCEPTION"];
  }
  if (!writeResult) {
    [NSException raise:@"WRITE_IMAGE_ERROR" format:@"WRITE_IMAGE_ERROR"];
  }
  
  //  Part 7: Return results
  StructRectifyImageResult rectifyImageResults;
  rectifyImageResults.success = writeResult;
  rectifyImageResults.width   = outputWidth;
  rectifyImageResults.height  = outputHeight;
  return rectifyImageResults;
}

@end
