#import "AnimationController.h"
#import "ImageUtil.h"
#import "ViewController.h"
#import "ShapeHandle.h"
#import "Record.h"

#define LOG_TOUCHES(fmt, ...)
//#define LOG_TOUCHES(fmt, ...) NSLog(fmt, ##__VA_ARGS__)

@interface AnimationController ()
@property(nonatomic, strong) Record *record;
@end

@implementation AnimationController {
    NSMutableDictionary *_touches2Points;
    Shape *_shape;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor greenColor];
    ViewController *glController = [self glController];
    UIView *childView = glController.view;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];

    UIImage *image = [UIImage imageNamed:@"tux.png"];
    _shape = [ImageUtil loadImage:image];
    glController.texture = image;
    glController.shape = _shape;
}

- (IBAction)startRecord {
    self.record = [Record new];
}

- (ViewController *)glController {
    ViewController *child = self.childViewControllers.firstObject;
    return child;
}

- (size_t)touchId:(UITouch *)touch {
    size_t ptr = (size_t) (__bridge CFTypeRef) touch;
    return ptr;
}

- (void)updateTouches:(NSSet *)touches shouldRemove:(BOOL)shouldRemove {
    map<int, point2d<double>> changed;

    for (UITouch *touch in touches) {
        size_t ptr = [self touchId:touch];
        CGPoint location = [touch locationInView:self.view];
        ShapeHandle *ap = _touches2Points[@((ptr))];
        ap.current = location;
        changed[ap.handleId] = { location.x, location.y };

        [self.glController updateGLOnMove];
        if (shouldRemove) {
            [_touches2Points removeObjectForKey:@((ptr))];
            LOG_TOUCHES(@"ENDED => %@", ap);
        }
        else {
            LOG_TOUCHES(@"MOVED => %@", ap);
        }
    }

    _shape->updateHandles(changed);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        size_t ptr = [self touchId:touch];
        CGPoint location = [touch locationInView:self.view];
        ShapeHandle *ap = [ShapeHandle pointWithStart:location];
        ap.current = ap.start;
        _touches2Points[@(ptr)] = ap;
        LOG_TOUCHES(@"NEW => %@", ap);
        _shape->addHandle(ap.handleId, location.x, location.y);
        [self.glController updateGLOnMove];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self updateTouches:touches shouldRemove:NO];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self updateTouches:touches shouldRemove:YES];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self updateTouches:touches shouldRemove:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _touches2Points = [NSMutableDictionary new];
}

@end