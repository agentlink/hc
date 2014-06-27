#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Shape.h"

@class AnimationController;
@class ShapeController;

@protocol AnimationDataSource
- (void)updateAnimation:(ShapeController *)controller;
@end

@interface ShapeController : GLKViewController {
}

@property(nonatomic, assign) UIImage *shapeImage;

@property(nonatomic, weak) id<AnimationDataSource> animationDataSource;

@property(nonatomic, readonly) BOOL hasShape;

- (void)updateOnShapeTransform;

- (void)releaseHandles:(vector<int>)vector update:(BOOL)update;

- (void)addHandle:(int)handleId atLocation:(CGPoint)location update:(BOOL)update;

- (void)handlesMoved:(map<int, point2d<double>>)map update:(BOOL)GL;

- (UIImage *)snapshot;
@end
