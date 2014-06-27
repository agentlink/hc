#import "AnimationController.h"
#import "ImageUtil.h"
#import "ShapeHandle.h"
#import "AnimationEvent.h"

#define LOG_TOUCHES(fmt, ...)
//#define LOG_TOUCHES(fmt, ...) NSLog(fmt, ##__VA_ARGS__)

typedef enum {
    IDLE,
    PLAYING,
    RECORDING
} State;

@interface AnimationController ()
@end

@implementation AnimationController {
    NSMutableDictionary *_touches2Points;
    Shape *_shape;
    NSMutableArray *_record;
    NSUInteger _playbackPosition;
    NSDate *_animationStart;
    State _state;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.view.backgroundColor = [UIColor greenColor];
    ViewController *glController = [self glController];
    UIView *childView = glController.view;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];

    [self resetShape];
}

- (void)resetShape {
    UIImage *image = [UIImage imageNamed:@"tux.png"];
    Shape *oldShape = _shape;
    _shape = [ImageUtil loadImage:image];
    ViewController *controller = self.glController;
    controller.texture = image;
    controller.shape = _shape;
    if (oldShape != nullptr) {
        delete oldShape;
    }
}

- (IBAction)startRecord {
    _record = [NSMutableArray new];
    _animationStart = [NSDate date];
    _state = RECORDING;
}

- (IBAction)stopRecord {
    _state = IDLE;
}

- (IBAction)playRecord {
    if (_state != IDLE) {
        [self stop];
        return;
    }

    [_touches2Points removeAllObjects];
    [self resetShape];
    _playbackPosition = 0;
    _animationStart = [NSDate date];
    _state = PLAYING;
}

- (void)stop {
    _state = IDLE;
}


- (ViewController *)glController {
    ViewController *child = self.childViewControllers.firstObject;
    return child;
}

- (size_t)touchId:(UITouch *)touch {
    size_t ptr = (size_t) (__bridge CFTypeRef) touch;
    return ptr;
}

- (void)updateTouches:(NSSet *)touches updateGL:(BOOL)updateGL {
    map<int, point2d<double>> changed;

    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:_animationStart];
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.view];
        ShapeHandle *handle = [self getHandle:touch];
        handle.current = location;
        point2d<double> point;
        point.x = location.x;
        point.y = location.y;
        int handleId = handle.handleId;
        changed[handleId] = point;

        if ([self isRecording]) {
            [_record addObject:[AnimationEvent eventWithTime:time
                                                        type:MOVE
                                                    handleId:handleId
                                                    position:location]];
        }

        LOG_TOUCHES(@"MOVED => %@", handle);
    }

    _shape->updateHandles(changed);
    if (updateGL) {
        [self.glController updateGLOnChange];
    }
}

- (ShapeHandle *)getHandle:(UITouch *)touch {
    size_t ptr = [self touchId:touch];
    ShapeHandle *ap = _touches2Points[@((ptr))];
    return ap;
}

- (BOOL)isPlaying {
    return _state == PLAYING;
}

- (BOOL)isRecording {
    return _state == RECORDING;
}

- (void)removeTouches:(NSSet *)touches {
    [self updateTouches:touches updateGL:NO];

    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:_animationStart];
    vector<int> removed;
    for (UITouch *touch in touches) {
        ShapeHandle *handle = [self getHandle:touch];
        int handleId = handle.handleId;
        removed.push_back(handleId);
        LOG_TOUCHES(@"ENDED => %@", handle);
        if ([self isRecording]) {
            CGPoint location = [touch locationInView:self.view];
            [_record addObject:[AnimationEvent eventWithTime:time
                                                        type:REMOVE
                                                    handleId:handleId
                                                    position:location]];
        }
    }
    _shape->releaseHandles(removed);
    [self.glController updateGLOnChange];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying) {
        return;
    }

    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:_animationStart];
    for (UITouch *touch in touches) {
        size_t ptr = [self touchId:touch];
        CGPoint location = [touch locationInView:self.view];
        ShapeHandle *ap = [ShapeHandle pointWithStart:location];
        ap.current = ap.start;
        _touches2Points[@(ptr)] = ap;
        LOG_TOUCHES(@"NEW => %@", ap);
        int handleId = ap.handleId;
        CGFloat x = location.x;
        CGFloat y = location.y;
        _shape->addHandle(handleId, x, y);
        [self.glController updateGLOnChange];
        if ([self isRecording]) {
            [_record addObject:[AnimationEvent eventWithTime:time
                                                        type:ADD
                                                    handleId:handleId
                                                    position:location]];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying) {
        return;
    }

    [self updateTouches:touches updateGL:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying) {
        return;
    }

    [self removeTouches:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying) {
        return;
    }

    [self removeTouches:touches];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _touches2Points = [NSMutableDictionary new];
    self.glController.animationDataSource = self;
    [self stop];
}


- (void)updateAnimation:(ViewController *)controller {
    if (!self.isPlaying) {
        return;
    }

    if (_playbackPosition >= _record.count) {
        [self stop];
        return;
    }

    NSDate *now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSinceDate:_animationStart];
    BOOL changed = NO;
    while (_playbackPosition < _record.count) {
        AnimationEvent *event = _record[_playbackPosition];
        if (event.time > time) {
            break;
        }

        _playbackPosition++;
        changed = YES;

        CGPoint position = event.position;
        switch (event.type) {
            case ADD:
                _shape->addHandle(event.handleId, position.x, position.y);
                break;
            case MOVE:
                _shape->updateHandle(event.handleId, position.x, position.y);
                break;
            case REMOVE:
                _shape->updateHandle(event.handleId, position.x, position.y);
            default:
                break;
        }
    }

    if (changed) {
        [controller updateGLOnChange];
    }

}

@end