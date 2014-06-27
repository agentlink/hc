#import "ImageUtil.h"


@implementation ImageUtil {

}

+ (Shape *)loadImage:(UIImage *)uiImage {
    CGImageRef image = [uiImage CGImage];
    unsigned width = CGImageGetWidth(image);
    unsigned height = CGImageGetHeight(image);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(
            NULL,
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


    void *data = CGBitmapContextGetData(context);

    IplImage *cvimage = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 4);
    cvSetData(cvimage, data, width * 4);
    cvSetImageCOI(cvimage, 4);

    IplImage *mask = cvCreateImage(cvSize(width, height), IPL_DEPTH_8U, 1);
    cvCopy(cvimage, mask, NULL);
    cvSmooth(mask, mask, 1, 4, 4, 0.1, 0.1);
    cvThreshold(mask, mask, 1, 255, CV_THRESH_BINARY);

    CvMemStorage *storage = cvCreateMemStorage(0);
    CvSeq *contour = 0;
    cvFindContours(mask, storage, &contour, sizeof(CvContour), CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE, cvPoint(0, 0));
    Shape *shape = new Shape(contour, width, height, NULL);

    cvReleaseMemStorage(&storage);

    cvSetData(mask, NULL, 0);
    cvSetData(cvimage, NULL, 0);

    cvReleaseImage(&mask);
    cvReleaseImage(&cvimage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    return shape;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end