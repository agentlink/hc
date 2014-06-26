#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#include "Shape.h"

@interface ViewController : GLKViewController {
}

@property(nonatomic) struct Shape *shape;

@property(nonatomic, strong) UIImage *texture;

- (void)updateGLOnMove;

@end
