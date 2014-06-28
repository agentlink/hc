#import <MobileCoreServices/MobileCoreServices.h>
#import "ImportShapeController.h"
#import "UIImage+Resizing.h"
#import "PaintView.h"


@interface ImportShapeController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>
@property(nonatomic, strong) IBOutlet UIImageView *imageView;
@property(nonatomic, strong) UIPopoverController *popover;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *collectionButton;
@property(nonatomic, strong) IBOutlet UIView *containerView;
@property(nonatomic, strong) IBOutlet PaintView *paintView;
@property(nonatomic, strong) UIImage *originalImage;
@end

@implementation ImportShapeController {
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    NSString *identifier = segue.identifier;

    if ([identifier isEqualToString:@"pick_camera"]) {
        UIImagePickerController *pc = segue.destinationViewController;
        pc.delegate = self;
        pc.sourceType = UIImagePickerControllerSourceTypeCamera;
        pc.mediaTypes = [NSArray arrayWithObject:(__bridge id) kUTTypeImage];
        pc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        pc.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        pc.allowsEditing = YES;
        [self.popover dismissPopoverAnimated:YES];
    }
}


- (IBAction)showCameraRoll:(id)sender {
    UIImagePickerController *pc = [UIImagePickerController new];
    pc.delegate = self;
    pc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pc.mediaTypes = [NSArray arrayWithObject:(__bridge id) kUTTypeImage];

    UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:pc];
    self.popover = popoverController;
    popoverController.delegate = self;
    [popoverController presentPopoverFromBarButtonItem:self.collectionButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.popover dismissPopoverAnimated:YES];
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

- (IBAction)removeBackground {
    UIImage *image = self.imageView.image;
    CGSize imageSize = image.size;
    CGSize newSize = CGSizeMake(imageSize.width, imageSize.height);
    UIGraphicsBeginImageContext(newSize);

    CGRect drawRect = CGRectMake(0, 0, newSize.width, newSize.height);

    CGSize paintSize = self.paintView.frame.size;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGFloat dx = -floorf((paintSize.width - imageSize.width) / 2);
    CGFloat dy = -floorf((paintSize.height - imageSize.height) / 2);
    [self.paintView drawRect:drawRect
                     context:ctx
                 translation:CGPointMake(dx, dy)
                   fillColor:[UIColor whiteColor]
                 strokeColor:[UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1]];

    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    self.imageView.image = finalImage;
    [self clearBorders];


}

- (void)setImageWithoutBackground:(UIImage *)image {
    self.imageView.image = image;
}

- (void)clearBorders {
    [self.paintView clearPaths];
    [self.paintView setNeedsDisplay];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}


- (IBAction)pan:(UIPanGestureRecognizer *)gr {
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

@end