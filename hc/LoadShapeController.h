#import <Foundation/Foundation.h>

@protocol LoadShapeControllerDelegate
- (void)imageSelected:(UIImage *)image;
@end

@interface LoadShapeController : UICollectionViewController<UICollectionViewDataSource>
@property(nonatomic, strong) id<LoadShapeControllerDelegate> selectionDelegate;

+ (NSString *)applicationDocumentsDirectory;
@end