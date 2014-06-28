#import "ImageUtil.h"
#import "IplImageWrapper.h"


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
    cvReleaseImage(&mask);

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

// NOTE You should convert color mode as RGB before passing to this function
+ (UIImage *)UIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Allocating the buffer for CGImage
    NSData *data =
            [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
            CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from chunk of IplImage
    CGImageRef imageRef = CGImageCreate(
            image->width, image->height,
            image->depth, image->depth * image->nChannels, image->widthStep,
            colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
            provider, NULL, false, kCGRenderingIntentDefault
    );
    // Getting UIImage from CGImage
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}

+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
            cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
    );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
            iplimage->imageData, iplimage->width, iplimage->height,
            iplimage->depth, iplimage->widthStep,
            colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
            contextRef,
            CGRectMake(0, 0, image.size.width, image.size.height),
            imageRef
    );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);

    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2RGB);
    cvReleaseImage(&iplimage);

    return ret;
}

@end