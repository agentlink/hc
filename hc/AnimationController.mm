#import "AnimationController.h"
#import "ShapeHandle.h"
#import "AnimationEvent.h"
#import "ImageUtil.h"
#import "UIImageUtil.h"
#import "ShapeInfo.h"

#define LOG_TOUCHES(fmt, ...)
//#define LOG_TOUCHES(fmt, ...) NSLog(fmt, ##__VA_ARGS__)

static const double EXPORT_TIME_PER_FRAME = 0.03;
static NSString *const SEGUE_SELECT_SHAPE = @"select_shape";
static const NSTimeInterval PIN_TIME_THRESHOLD = 0.5f;
static const float PIN_DISTANCE_THRESHOLD = 30;

typedef enum {
    IDLE,
    PLAYING,
    RECORDING
} State;

@interface AnimationController ()
@end

@implementation AnimationController {
    NSMutableDictionary *_touches2Points;
    NSMutableSet *_pins;
    NSMutableArray *_record;
    NSUInteger _playbackPosition;
    NSDate *_animationStart;
    State _state;
    NSDate *_recordZero;
    NSDate *_recordStart;
    NSDate *_playbackStart;
    NSDateFormatter *_dateFormatter;
}


- (void)resetShape {
    self.shapeController.shapeInfo = _shape;

    _animationStart = [NSDate date];
}

- (IBAction)startRecord {
    if (!self.shapeController.hasShape) {
        return;
    }

    [self stop];

    _recordZero = _animationStart;
    _recordStart = [NSDate date];
    self.state = RECORDING;
}

- (IBAction)stop {
    self.state = IDLE;
}

- (IBAction)playRecord {
    if (!self.shapeController.hasShape || !self.hasRecord) {
        return;
    }

    [self stop];

    self.state = PLAYING;
    NSDate *now = [NSDate date];
    _playbackStart = now;
    [self preparePlayback];
}

- (void)setState:(State)state {
    _state = state;
    self.shapeController.shouldDrawHandles = _state != PLAYING;
    [self updateButtons];
}

- (void)updateButtons {
    NSMutableArray *toolbarItems = [NSMutableArray new];
    [toolbarItems addObject:self.loadShapeItem];
    [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:NULL]];
    if (self.hasRecord) {
        [toolbarItems addObject:self.exportItem];
        [toolbarItems addObject:[self createfixedSpaceItem]];
        [toolbarItems addObject:self.playItem];
        [toolbarItems addObject:[self createfixedSpaceItem]];
    }
    [toolbarItems addObject:self.recordItem];

    self.toolbarItems = [toolbarItems copy];
}

- (UIBarButtonItem *)createfixedSpaceItem {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:NULL];
    item.width = 44;
    return item;
}

- (void)preparePlayback {
    [_touches2Points removeAllObjects];
    [_pins removeAllObjects];

    NSTimeInterval preRecordTime = [_recordStart timeIntervalSinceDate:_recordZero];

    [self resetShape];
    _playbackPosition = 0;
    [self fastForward:preRecordTime];
}

- (BOOL)hasRecord {
    return _recordZero != nil;
}

- (void)fastForward:(NSTimeInterval)interval {
    ShapeController *shapeController = self.shapeController;

    for (AnimationEvent *event in _record) {
        if (event.time >= interval) {
            break;
        }

        switch (event.type) {
            case ADD:
                [shapeController addHandle:event.handleId atLocation:event.position update:NO];
                break;
            case REMOVE:
                [self moveHandle:shapeController position:event.position handleId:event.handleId];
                [self releaseHandle:shapeController handleId:event.handleId];
                break;
            case MOVE:
            default:
                break;
        }
        _playbackPosition++;
    }

    [shapeController updateOnShapeTransform];
}

- (ShapeController *)shapeController {
    ShapeController *child = self.childViewControllers.firstObject;
    return child;
}

- (size_t)touchId:(UITouch *)touch {
    return (size_t) (__bridge CFTypeRef) touch;
}

- (void)updateTouches:(NSSet *)touches updateShape:(BOOL)updateGL {
    map<int, point2d<double>> changed;

    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:_animationStart];
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInView:self.view];
        ShapeHandle *handle = [self getHandle:touch];
        CGPoint actualLocation = CGPointMake(location.x + handle.xCorrection, location.y + handle.yCorrection);
        handle.current = actualLocation;
        point2d<double> point;
        point.x = actualLocation.x;
        point.y = actualLocation.y;
        int handleId = handle.handleId;
        changed[handleId] = point;

        [_record addObject:[AnimationEvent eventWithTime:time
                                                    type:MOVE
                                                handleId:handleId
                                                position:actualLocation]];

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

- (void)removeTouches:(NSSet *)touches {
    NSMutableSet *moves = [NSMutableSet new];

    NSDate *now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSinceDate:_animationStart];
    vector<int> removed;
    for (UITouch *touch in touches) {
        ShapeHandle *handle = [self getHandle:touch];
        NSTimeInterval touchDuration = [now timeIntervalSinceDate:handle.lastTouchedAt];
        BOOL longTouch = touchDuration > PIN_TIME_THRESHOLD;

        if (longTouch) {
            [moves addObject:touch];
        }
    }

    [self updateTouches:moves updateShape:NO];

    for (UITouch *touch in touches) {
        ShapeHandle *handle = [self getHandle:touch];
        int handleId = handle.handleId;
        NSTimeInterval touchDuration = [now timeIntervalSinceDate:handle.lastTouchedAt];
        BOOL longTouch = touchDuration > PIN_TIME_THRESHOLD;

        BOOL isPin = [_pins containsObject:handle];
        if (longTouch != isPin) {
            [_touches2Points removeObjectForKey:@([self touchId:touch])];
            [_pins removeObject:handle];
            removed.push_back(handleId);
            CGPoint location = [touch locationInView:self.view];
            [_record addObject:[AnimationEvent eventWithTime:time
                                                        type:REMOVE
                                                    handleId:handleId
                                                    position:location]];
            LOG_TOUCHES(@"ENDED => %@", handle);
        }
        else if (!isPin) {
            [_pins addObject:handle];
        }
    }

    [self.shapeController releaseHandles:removed update:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying || !self.shapeController.hasShape) {
        return;
    }

    ShapeHandle *pin = nil;
    UITouch *pinTouch = nil;

    NSDate *now = [NSDate date];
    NSTimeInterval time = [now timeIntervalSinceDate:_animationStart];
    for (UITouch *touch in touches) {
        size_t ptr = [self touchId:touch];
        CGPoint location = [touch locationInView:self.view];

        BOOL foundPin = NO;
        if (!pin) {
            pin = [self findPin:location];
            if (pin) {
                pinTouch = touch;
                foundPin = YES;
                _touches2Points[@(ptr)] = pin;
                CGPoint pinPosition = pin.current;
                pin.xCorrection = pinPosition.x - location.x;
                pin.yCorrection = pinPosition.y - location.y;
            }
        }

        ShapeHandle *ap = foundPin ? pin : [ShapeHandle pointWithStart:location];
        ap.lastTouchedAt = now;
        _touches2Points[@(ptr)] = ap;
        int handleId = ap.handleId;

        if (!foundPin) {
            LOG_TOUCHES(@"NEW => %@", ap);
            [self.shapeController addHandle:handleId atLocation:location update:YES];
            [_record addObject:[AnimationEvent eventWithTime:time
                                                        type:ADD
                                                    handleId:handleId
                                                    position:location]];
        }
    }

    if (pin) {
        [self updateTouches:[NSSet setWithObject:pinTouch] updateShape:YES];
    }
}

- (ShapeHandle *)findPin:(CGPoint)location {
    ShapeHandle *pin;
    for (ShapeHandle *handle in _pins) {
        CGPoint handlePos = handle.current;
        float dist = hypot(handlePos.x - location.x, handlePos.y - location.y);
        if (dist <= PIN_DISTANCE_THRESHOLD) {
            pin = handle;
        }
    }
    return pin;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.isPlaying || !self.shapeController.hasShape) {
        return;
    }

    [self updateTouches:touches updateShape:YES];
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
    _pins = [NSMutableSet new];
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

    NSDate *now = [NSDate date];
    NSTimeInterval playbackTime = [now timeIntervalSinceDate:_playbackStart];

    [self updateAnimation:controller playbackTime:playbackTime];
}

- (BOOL)updateAnimation:(ShapeController *)controller playbackTime:(NSTimeInterval)playbackTime {
    NSTimeInterval preRecordTime = [_recordStart timeIntervalSinceDate:_recordZero];
    if (_playbackPosition >= _record.count) {
        [self stop];
        return NO;
    }

    NSTimeInterval time = playbackTime + preRecordTime;
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
                [self moveHandle:controller position:position handleId:handleId];
                break;
            }
            case REMOVE: {
                [self releaseHandle:controller handleId:handleId];
            }
            default:
                break;
        }
    }

    if (changed) {
        [controller updateOnShapeTransform];
    }

    return changed;
}

- (void)moveHandle:(ShapeController *)controller position:(CGPoint)position handleId:(int)handleId {
    map<int, point2d<double>> moved;
    point2d<double> location;
    location.x = position.x;
    location.y = position.y;
    moved[handleId] = location;
    [controller handlesMoved:moved update:NO];
}

- (void)releaseHandle:(ShapeController *)controller handleId:(int)handleId {
    vector<int> released;
    released.push_back(handleId);
    [controller releaseHandles:released update:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([SEGUE_SELECT_SHAPE isEqual:segue.identifier]) {
        LoadShapeController *sc = segue.destinationViewController;
        sc.selectionDelegate = self;
    }

    [super prepareForSegue:segue sender:sender];
}

- (void)shapeSelected:(ShapeInfo *)info {
    self.shape = info;
    [self.navigationController popToViewController:self animated:YES];
}

- (void)clearRecord {
    _record = [NSMutableArray new];
    _recordZero = nil;
    _recordStart = nil;
}

- (void)setShape:(ShapeInfo *)shape {
    [self stop];
    _shape = shape;
    [self clearRecord];
    [self resetShape];
    [self stop];
}

- (IBAction)export {
    if (!self.hasRecord) {
        return;
    }

    [self stop];

    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy'_'MM'_'dd'__'HH'_'mm'_'ss";
    }

    NSDate *start = [NSDate date];
    NSString *dateString = [_dateFormatter stringFromDate:start];
    NSString *directoryName = [NSString stringWithFormat:@"export_%@", dateString];
    NSString *directory = [[UIImageUtil applicationDocumentsDirectory] stringByAppendingPathComponent:directoryName];

    NSError *error = nil;
    BOOL dirCreated = [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    if (!dirCreated) {
        NSLog(@"dir %@ can't be created: %@", directory, error);
        return;
    }

    self.state = PLAYING;

    [self preparePlayback];

    ShapeController *shapeController = self.shapeController;

    int frameIndex = 0;
    NSData *imageData = nil;
    while (_state == PLAYING) {
        BOOL changed = [self updateAnimation:shapeController playbackTime:frameIndex * EXPORT_TIME_PER_FRAME];
        if (changed || !imageData) {
            @autoreleasepool {
                UIImage *image = [shapeController snapshot];
                CGSize size = image.size;
                UIImage *scaledImage = [ImageUtil imageWithImage:image scaledToSize:CGSizeMake(floor(size.width / 2), floor(size.height / 2))];
                imageData = UIImagePNGRepresentation(scaledImage);
            }
        }

        NSString *name = [NSString stringWithFormat:@"%05d.png", frameIndex];
        [imageData writeToFile:[directory stringByAppendingPathComponent:name] atomically:YES];
        frameIndex++;
    }

    NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:start];
    double fps = 1 / EXPORT_TIME_PER_FRAME;
    double rFps = frameIndex / time;
    double total = frameIndex * EXPORT_TIME_PER_FRAME;
    NSLog(@"exported %d frames at %.2f FPS (%.2f s) in %.2f sec (%.2f f/s) to %@", frameIndex, fps, total, time, rFps, directory);
}

@end