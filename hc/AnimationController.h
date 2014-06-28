#import <Foundation/Foundation.h>
#import "ShapeController.h"
#import "LoadShapeController.h"

@class ShapeInfo;

@interface AnimationController : UIViewController <AnimationDataSource, LoadShapeControllerDelegate>

@property(nonatomic, strong) ShapeInfo *shape;

- (BOOL)hasRecord;

@end