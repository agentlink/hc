#import "ImageUtil.h"
#import "IplImageWrapper.h"
#import "ShapeInfo.h"


@implementation ImageUtil {

}

+ (Shape *)loadImage:(ShapeInfo *)shapeInfo {
    CGImageRef image = [shapeInfo.image CGImage];
    unsigned width = CGImageGetWidth(image);
    unsigned height = CGImageGetHeight(image);
    
    UIImage *weights = shapeInfo.weights;
    
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

    Mat weightsMask;
//    if (weights != nil)
//       weightsMask = [ImageUtil CreateMatFromUIImage:weights];
    Shape *shape = new Shape(contour, width, height, NULL);//weights == nil ? NULL : &weightsMask);

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
+ (UIImage *)UIImageFromMat:(Mat)cvMat {
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
            kCGImageAlphaPremultipliedLast,             // bitmap info
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

+ (Mat)CreateMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    if  (image.imageOrientation == UIImageOrientationLeft
            || image.imageOrientation == UIImageOrientationRight) {
        cols = image.size.height;
        rows = image.size.width;
    }

    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)


    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
            cols,                       // Width of bitmap
            rows,                       // Height of bitmap
            8,                          // Bits per component
            cvMat.step[0],              // Bytes per row
            colorSpace,                 // Colorspace
//            kCGImageAlphaNoneSkipLast |
//                    kCGBitmapByteOrderDefault); // Bitmap info flags
            kCGImageAlphaPremultipliedLast);

        CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                image.CGImage);
        CGContextRelease(contextRef);

    if  (image.imageOrientation == UIImageOrientationLeft) {
//        cv::Mat dst;
        cv::transpose(cvMat, cvMat);
        cv::flip(cvMat, cvMat, 0);
    }

    if  (image.imageOrientation == UIImageOrientationRight) {
//        cv::Mat dst;
        cv::transpose(cvMat, cvMat);
        cv::flip(cvMat, cvMat, 1);
    }

    if  (image.imageOrientation == UIImageOrientationDown) {
//        cv::Mat dst;
        cv::flip(cvMat, cvMat, 1);
        cv::flip(cvMat, cvMat, 0);
    }

    return cvMat;
}

@end