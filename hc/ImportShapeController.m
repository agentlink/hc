#import <MobileCoreServices/MobileCoreServices.h>
#import "ImportShapeController.h"


@interface ImportShapeController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>
@property(nonatomic, strong) UIPopoverController *popover;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *collectionButton;
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

- (IBAction)removeBackground {
    UIColor *fillColor = [UIColor whiteColor];
    UIColor *strokeColor = [UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:1];

    UIImage *borders = [self maskWithFillColor:fillColor strokeColor:strokeColor];
    [self clearBorders];

//    UIImage *result = [UIImageUtil removeBackground:image borders:borders];
    self.imageView.image = borders;
}

- (void)setImageWithoutBackground:(UIImage *)image {
    self.imageView.image = image;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.popover = nil;
}


@end