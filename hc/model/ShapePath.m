#import "ShapePath.h"
#import "ShapeInfo.h"


@implementation ShapePath {

}

- (instancetype)initWithImagePath:(NSString *)imagePath {
    self = [super init];
    if (self) {
        _imagePath = imagePath;
    }

    return self;
}

- (NSString *)weightsPath {
    return [self.shapeDir stringByAppendingPathComponent:[ShapePath weightsFileName]];
}

+ (instancetype)pathWithImagePath:(NSString *)imagePath {
    return [[self alloc] initWithImagePath:imagePath];
}

- (NSString *)shapeDir {
    return [_imagePath stringByDeletingLastPathComponent];
}

+ (NSString *)weightsFileName {
    return @"weights.png";
}

- (ShapeInfo *)loadShape {
    UIImage *image = [self loadImage];
    UIImage *weights = nil;
    weights = [[UIImage alloc] initWithContentsOfFile:self.weightsPath];
    return [ShapeInfo infoWithImage:image weights:weights];
}

- (UIImage *)loadImage {
    return [[UIImage alloc] initWithContentsOfFile:_imagePath];
}
@end