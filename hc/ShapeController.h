#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Shape.h"

@class AnimationController;
@class ShapeController;
@class ShapeInfo;

@protocol AnimationDataSource
- (void)updateAnimation:(ShapeController *)controller;
@end

@interface ShapeController : GLKViewController {
}

@property(nonatomic, weak) id<AnimationDataSource> animationDataSource;

@property(nonatomic, readonly) BOOL hasShape;

- (void)setShapeInfo:(ShapeInfo *)info;

- (void)updateOnShapeTransform;

- (void)releaseHandles:(vector<int>)vector update:(BOOL)update;

- (void)addHandle:(int)handleId atLocation:(CGPoint)location update:(BOOL)update;

- (void)handlesMoved:(map<int, point2d<double>>)map update:(BOOL)GL;

- (UIImage *)snapshot;
@end
