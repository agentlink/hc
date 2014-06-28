#import <Foundation/Foundation.h>
#include "Shape.h"


@interface ImageUtil : NSObject
+ (Shape *)loadImage:(UIImage *)uiImage;

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

+ (UIImage *)UIImageFromIplImage:(IplImage *)image;

+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image;
@end