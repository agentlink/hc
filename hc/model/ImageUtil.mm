#import "ImageUtil.h"
#include "Shape.h"


@implementation ImageUtil {

}

+ (Shape *)loadImage {
    CGImageRef image = [[UIImage imageNamed:@"tux.png"] CGImage];
    unsigned width = CGImageGetWidth(image);
    unsigned height = CGImageGetHeight(image);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    void *data = malloc(width*height*4* sizeof(char));

    CGContextRef context = CGBitmapContextCreate(
            data,
            width,
            height,
            8,
            width * 4,
            colorSpace,
            kCGImageAlphaPremultipliedLast);

    CGContextDrawImage(
            context,
            CGRectMake(0, 0, width, height),
            image);


    IplImage *cvimage = cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 4);
    cvSetData(cvimage, data, width*4);
    cvSetImageCOI(cvimage,4);

    IplImage * mask = cvCreateImage(cvSize(width,height), IPL_DEPTH_8U, 1);
    cvCopy(cvimage, mask, NULL);
    cvSmooth(mask, mask, 1, 4, 4, 0.1, 0.1);
    cvThreshold(mask, mask, 1, 255, CV_THRESH_BINARY);
    CvMemStorage * storage = cvCreateMemStorage(0);
    CvSeq * contour = 0;
    cvFindContours(mask, storage, &contour, sizeof(CvContour), CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cvPoint(0, 0));
    Shape *shape = new Shape(contour, width, height);

    cvReleaseImage(&mask);
    cvReleaseImage(&cvimage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return shape;
}

@end