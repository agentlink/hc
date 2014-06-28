#import "UIImageUtil.h"
#import "ImageUtil.h"
#include "RobustMatting.h"


@implementation UIImageUtil {

}

+ (UIImage *)removeBackground:(UIImage *)image borders:(UIImage *)borders {
    IplImage *iplImage = [ImageUtil CreateIplImageFromUIImage:image];
    IplImage *iplBorders = [ImageUtil CreateIplImageFromUIImage:borders];
    RobustMatting rm;
    IplImage *trimap = rm.GenerateTrimap(iplBorders);
    IplImage *iplResult = rm.CalculateMatting(iplImage, trimap);

    UIImage *result = [ImageUtil UIImageFromIplImage:iplResult];
//    UIImage *result = [ImageUtil UIImageFromIplImage:trimap];
    return result;
}

@end