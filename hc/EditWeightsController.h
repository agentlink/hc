#import <Foundation/Foundation.h>
#import "ImagePaintController.h"

@class LoadShapeController;

@protocol EditWeightsControllerDelegate
- (void)edited:(UIImage *)image weights:(UIImage *)weights;
@end

@interface EditWeightsController : ImagePaintController
@property(nonatomic, weak) id<EditWeightsControllerDelegate> weightDelegate;
@end
