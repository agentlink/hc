#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Shape.h"

@class AnimationController;
@class ViewController;

@protocol AnimationDataSource
- (void)updateAnimation:(ViewController *)controller;
@end

@interface ViewController : GLKViewController {
}

@property(nonatomic) struct Shape *shape;

@property(nonatomic, strong) UIImage *texture;

@property(nonatomic, weak) id<AnimationDataSource> animationDataSource;

- (void)updateGLOnChange;

@end
