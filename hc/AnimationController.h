#import <Foundation/Foundation.h>
#import "ShapeController.h"
#import "LoadShapeController.h"

@class Record;


@interface AnimationController : UIViewController <AnimationDataSource, LoadShapeControllerDelegate>
@property(nonatomic, strong) UIImage *image;

- (BOOL)hasRecord;
@end