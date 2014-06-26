#import "AnimationController.h"


@implementation AnimationController {

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor greenColor];
    UIViewController * child = self.childViewControllers.firstObject;
    UIView *childView = child.view;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];
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