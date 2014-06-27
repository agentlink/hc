#import <Foundation/Foundation.h>
#import "ShapeController.h"
#import "LoadShapeController.h"

@class Record;


static NSString *const SEGUE_SELECT_SHAPE = @"select_shape";

@interface AnimationController : UIViewController <AnimationDataSource, LoadShapeControllerDelegate>
@property(nonatomic, strong) UIImage *image;
@end