#import <Foundation/Foundation.h>
#import "ShapeController.h"
#import "LoadShapeController.h"

@interface AnimationController : UIViewController <AnimationDataSource, LoadShapeControllerDelegate>
@property(nonatomic, strong) UIImage *image;

- (BOOL)hasRecord;
@end