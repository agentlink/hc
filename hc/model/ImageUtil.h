#import <Foundation/Foundation.h>
#include "Shape.h"

using namespace cv;
@class ShapeInfo;

@interface ImageUtil : NSObject
+ (Shape *)loadImage:(ShapeInfo *)uiImage;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)UIImageFromMat:(Mat)cvMat;

+ (Mat)CreateMatFromUIImage:(UIImage *)image;
@end