#import "ShapeInfo.h"


@implementation ShapeInfo {

}

- (instancetype)initWithImage:(UIImage *)image weights:(UIImage *)weights {
    self = [super init];
    if (self) {
        self.image = image;
        self.weights = weights;
    }

    return self;
}

+ (instancetype)infoWithImage:(UIImage *)image weights:(UIImage *)weights {
    return [[self alloc] initWithImage:image weights:weights];
}


@end
