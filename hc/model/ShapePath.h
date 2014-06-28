#import <Foundation/Foundation.h>

@class ShapeInfo;


@interface ShapePath : NSObject

@property(nonatomic, readonly) NSString *imagePath;
@property(nonatomic, readonly) NSString *weightsPath;

@property(nonatomic, readonly) NSString *shapeDir;

- (instancetype)initWithImagePath:(NSString *)imagePath;

+ (instancetype)pathWithImagePath:(NSString *)imagePath;

- (ShapeInfo *)loadShape;

+ (NSString *)weightsFileName;


- (UIImage *)loadImage;
@end