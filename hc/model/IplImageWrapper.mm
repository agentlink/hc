#include <opencv2/opencv.hpp>
#import "IplImageWrapper.h"


@interface IplImageWrapper ()
@property(nonatomic, assign) IplImage *iplImage;
@end

@implementation IplImageWrapper {
    CGContextRef _context;
    CGColorSpaceRef _colorSpace;
}

+ (IplImageWrapper *)wrapperWithUIImage:(UIImage *)uiImage {
    CGImageRef image = uiImage.CGImage;

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

    IplImageWrapper *wrapper = [IplImageWrapper new];
    wrapper.iplImage = cvimage;
    wrapper->_context = context;
    wrapper->_colorSpace = colorSpace;
    return wrapper;
}

- (void)dealloc {
    cvSetData(_iplImage, NULL, 0);
    cvReleaseImage(&_iplImage);
    CGColorSpaceRelease(_colorSpace);
    CGContextRelease(_context);
}

@end