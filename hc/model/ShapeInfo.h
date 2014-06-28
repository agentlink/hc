#import <Foundation/Foundation.h>


@interface ShapeInfo : NSObject
@property(nonatomic, strong) UIImage *image;
@property(nonatomic, strong) UIImage *weights;

- (instancetype)initWithImage:(UIImage *)image weights:(UIImage *)weights;

+ (instancetype)infoWithImage:(UIImage *)image weights:(UIImage *)weights;

@end
