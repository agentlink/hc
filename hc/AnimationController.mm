#import "AnimationController.h"
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
    NSMutableArray *_record;
    NSUInteger _playbackPosition;
    NSDate *_animationStart;
    State _state;
}


- (void)resetShape {
    self.shapeController.shapeImage = _image;
}

- (IBAction)startRecord {
    if (self.isPlaying) {
        [self stop];
    }

    if (!self.shapeController.hasShape) {
        return;
    }

    [self clearRecord];
    _animationStart = [NSDate date];
    _state = RECORDING;
}

- (IBAction)stop {
    _state = IDLE;
}

- (IBAction)playRecord {
    if (!self.shapeController.hasShape) {
        return;
    }

    [self stop];

    [_touches2Points removeAllObjects];
    [self resetShape];
    _playbackPosition = 0;
    _animationStart = [NSDate date];
    _state = PLAYING;
}

- (ShapeController *)shapeController {
    ShapeController *child = self.childViewControllers.firstObject;
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

    [self.shapeController handlesMoved:changed update:updateGL];
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

    [self.shapeController releaseHandles:removed update:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying || !self.shapeController.hasShape) {
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

        [self.shapeController addHandle:handleId atLocation:location update:YES];
        if ([self isRecording]) {
            [_record addObject:[AnimationEvent eventWithTime:time
                                                        type:ADD
                                                    handleId:handleId
                                                    position:location]];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying || !self.shapeController.hasShape) {
        return;
    }

    [self updateTouches:touches updateGL:YES];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying || !self.shapeController.hasShape) {
        return;
    }

    [self removeTouches:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying || !self.shapeController.hasShape) {
        return;
    }

    [self removeTouches:touches];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    ShapeController *shapeController = self.shapeController;
    UIView *childView = shapeController.view;
    childView.frame = self.view.bounds;
    [self.view addSubview:childView];

    _touches2Points = [NSMutableDictionary new];
    shapeController.animationDataSource = self;
    [self stop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!self.shapeController.hasShape) {
        [self performSegueWithIdentifier:SEGUE_SELECT_SHAPE sender:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)updateAnimation:(ShapeController *)controller {
    if (!self.isPlaying || !self.shapeController.hasShape) {
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
        int handleId = event.handleId;
        switch (event.type) {
            case ADD:
                [controller addHandle:handleId atLocation:position update:NO];
                break;
            case MOVE: {
                map<int, point2d<double>> moved;
                point2d<double> location;
                location.x = position.x;
                location.y = position.y;
                moved[handleId] = location;
                [controller handlesMoved:moved update:NO];
                break;
            }
            case REMOVE: {

                vector<int> released;
                released.push_back(handleId);
            }
            default:
                break;
        }
    }

    if (changed) {
        [controller updateOnShapeTransform];
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([SEGUE_SELECT_SHAPE isEqual:segue.identifier]) {
        LoadShapeController *sc = segue.destinationViewController;
        sc.selectionDelegate = self;
    }

    [super prepareForSegue:segue sender:sender];
}

- (void)imageSelected:(UIImage *)image {
    [self stop];

    self.image = image;
}

- (void)clearRecord {
    _record = [NSMutableArray new];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self clearRecord];
    [self resetShape];
}

@end