#import "EditWeightsController.h"


@implementation EditWeightsController {

}

- (IBAction)done {
    UIImage *weights = [self maskWithFillColor:[UIColor blackColor] strokeColor:[UIColor whiteColor]];
    [_weightDelegate edited:self.originalImage weights:weights];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
