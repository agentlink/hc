#import <Foundation/Foundation.h>
#include "Shape.h"


@interface ImageUtil : NSObject
+ (Shape *)loadImage:(UIImage *)uiImage;
@end