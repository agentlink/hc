#import "UIImage+Resizing.h"
#import "ImportShapeController.h"


@interface ImagePaintController ()
@end

@implementation ImagePaintController {

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self resetChanges];
}

- (void)setOriginalImage:(UIImage *)originalImage {
    _originalImage = originalImage;
    [self resetChanges];
}

- (IBAction)resetChanges {
    UIImage *image = self.originalImage;
    CGSize size = image.size;

    CGFloat width = size.width;
    CGFloat height = size.height;
    if (width > IMAGE_MAX_WIDTH || height > IMAGE_MAX_HEIGHT) {
        image = [image scaleToFitSize:CGSizeMake(IMAGE_MAX_WIDTH, IMAGE_MAX_HEIGHT)];
    }

    self.imageView.image = image;
    [self clearBorders];
}

- (void)clearBorders {
    [self.paintView clearPaths];
    [self.paintView setNeedsDisplay];
}

- (IBAction)draw:(UIPanGestureRecognizer *)gr {
    if (!self.imageView.image) {
        return;
    }

    PaintView *paintView = self.paintView;
    CGPoint location = [gr locationInView:paintView];

    switch (gr.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan:
            [paintView startPath:location];
            break;
        case UIGestureRecognizerStateChanged:
            [paintView continuePath:location];
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            [paintView endPath:location];
            break;
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (UIImage *)maskWithFillColor:(UIColor *)fillColor strokeColor:(UIColor *)strokeColor {
    CGSize imageSize = self.imageView.image.size;
    CGSize newSize = CGSizeMake(imageSize.width, imageSize.height);
    UIGraphicsBeginImageContext(newSize);

    CGRect drawRect = CGRectMake(0, 0, newSize.width, newSize.height);

    CGSize paintSize = self.paintView.frame.size;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat dx = -floorf((paintSize.width - imageSize.width) / 2);
    CGFloat dy = -floorf((paintSize.height - imageSize.height) / 2);
    [self.paintView drawRect:drawRect context:ctx translation:CGPointMake(dx, dy) fillColor:fillColor strokeColor:strokeColor useAntialiasing:NO];

    UIImage *borders = UIGraphicsGetImageFromCurrentImageContext();
    return borders;
}
@end
