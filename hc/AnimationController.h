#import <Foundation/Foundation.h>
#import "ShapeController.h"
#import "LoadShapeController.h"

@class ShapeInfo;

@interface AnimationController : UIViewController <AnimationDataSource, LoadShapeControllerDelegate>

@property(nonatomic, strong) ShapeInfo *shape;

@property(nonatomic, strong) IBOutlet UIBarButtonItem *loadShapeItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *exportItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *playItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *recordItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *resetSceneItem;
@property(nonatomic, strong) IBOutlet UIBarButtonItem *toggleTrianglesItem;

- (BOOL)hasRecord;

@end