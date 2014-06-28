#import <Foundation/Foundation.h>
#include "Shape.h"

using namespace cv;

@interface ImageUtil : NSObject
+ (Shape *)loadImage:(UIImage *)uiImage;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)UIImageFromMat:(Mat)cvMat;

+ (Mat)CreateMatFromUIImage:(UIImage *)image;
@end