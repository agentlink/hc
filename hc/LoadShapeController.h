#import <Foundation/Foundation.h>

@class ShapeInfo;


@protocol LoadShapeControllerDelegate
- (void)shapeSelected:(ShapeInfo *)info;
@end

@interface LoadShapeController : UICollectionViewController<UICollectionViewDataSource>
@property(nonatomic, strong) id<LoadShapeControllerDelegate> selectionDelegate;

@end