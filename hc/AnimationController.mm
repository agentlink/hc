#import "AnimationController.h"
#import "ImageUtil.h"
#import "ViewController.h"


@implementation AnimationController {

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor greenColor];
    ViewController *glController = [self glController];
    UIView *childView = glController.view;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];

    UIImage *image = [UIImage imageNamed:@"tux.png"];
    Shape *shape = [ImageUtil loadImage:image];
    glController.texture = image;
    glController.shape = shape;
}

- (ViewController *)glController {
    ViewController* child = self.childViewControllers.firstObject;
    return child;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


@end